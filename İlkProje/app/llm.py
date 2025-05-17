import os
import requests
import json
import google.generativeai as genai

class LLMService:

    def __init__(self):
        # Varsayılan olarak Gemini kullanır , ancak hata durumunda Ollama'ya geçiş yapılır.
        try:

            gemini_api_key = os.environ.get('GEMINI_API_KEY')
            if not gemini_api_key:
                raise ValueError("Gemini API anahtarı bulunamadı")

            genai.configure(api_key=gemini_api_key)
            self.model = os.environ.get('GEMINI_MODEL', 'gemini-2.5-flash')
            self.use_ollama = False
            print("Gemini API kullanılıyor")
        except Exception as e:
            print(f"Gemini API hatası: {str(e)}")
            print("Ollama'ya geçiliyor...")
            # Fallback to Ollama
            self.use_ollama = True
            self.ollama_base_url = os.environ.get('OLLAMA_BASE_URL', 'http://localhost:11434')
            self.ollama_model = os.environ.get('OLLAMA_MODEL', 'llama2')

    def generate_code(self, prompt):
        """
        Verilen isteğe göre Python kodu üret.

        Parametreler:
            prompt (str): Kullanıcının kod üretimi için isteği

        Dönüş:
            tuple: (title, code) - Üretilen başlık ve kod
        """
        system_prompt = """
        Sen kullanıcı isteklerine göre Python kodu üreten bir yapay zeka asistanısın.
        Görevin, aşağıdaki yapıya sahip Job sınıfını genişleten Python kodu oluşturmaktır:

        ```python
        # S4E tarafından sağlanan Task sınıfının yer tutucu implementasyonu
        class Task:
            def __init__(self):
                self.asset = {}
                self.param = {'max_score': 10}
                self.output = {}
                self.score = 0

        class Job(Task):
            def run(self):
                asset = self.asset
                self.output['detail'] = []  # İşten gelen detaylı sonuç
                self.output['compact'] = []  # İşten gelen kısa sonuç
                self.output['video'] = []  # İşi yapmak için adımlar, komutlar vb.

            def calculate_score(self):
                # Skor 0 ile 10 arasında bir sayıdır:
                # - score == 1: bilgi
                # - 1 < score < 4: düşük
                # - 4 <= score < 7: orta
                # - 7 <= score < 9: yüksek
                # - 9 <= score < 11: kritik
                self.score = self.param['max_score']
        ```

        Yanıtın şunları içermelidir:
        1. Kod için kısa, açıklayıcı bir başlık (tek satır)
        2. Job sınıfını genişleten Python kodu

        Yanıtını tam olarak şu şekilde biçimlendir:
        TITLE: [Başlığınız burada]

        ```python
        [Python kodunuz burada]
        ```

        Kodun iyi belgelenmiş, en iyi uygulamaları takip eden ve kullanıma hazır olduğundan emin ol.
        Özellikle, run() metodunu ve calculate_score() metodunu doğru şekilde uyguladığından emin ol.
        run() metodunda, output sözlüğünün detail, compact ve video anahtarlarını kullanarak anlamlı sonuçlar üretmelisin.
        calculate_score() metodunda, işin önemine göre anlamlı bir skor hesaplamalısın.
        """

        if self.use_ollama:
            return self._generate_with_ollama(system_prompt, prompt)
        else:
            return self._generate_with_gemini(system_prompt, prompt)

    def _generate_with_gemini(self, system_prompt, user_prompt):
        """Gemini API kullanarak kod üret"""
        try:
            print(f"Gemini API anahtarı: {os.environ.get('GEMINI_API_KEY')[:5]}...")
            print(f"Kullanılan model: {self.model}")

            # Gemini API'yi yeniden yapılandır
            gemini_api_key = os.environ.get('GEMINI_API_KEY')
            genai.configure(api_key=gemini_api_key)

            #  self.model (gemini 2.5 flash) kullanılıyor.
            print(f"Model kullanılıyor: {self.model}")
            model = genai.GenerativeModel(self.model)

            # Gemini modeli için yapılandırma
            generation_config = {
                "temperature": 0.7,
                "top_p": 0.95,
                "top_k": 40,
                "max_output_tokens": 2048,
            }

            # Birleştirilmiş prompt. Sistem prompptu ile user prommpt birleştirildi.
            # Geminide OpenAI a göre biraz daha farklı işliyor.
            birlestirilmis_prompt = f"{system_prompt}\n\nKullanıcı İsteği: {user_prompt}"

            # API çağrısı
            response = model.generate_content(
                birlestirilmis_prompt,
                generation_config=generation_config
            )

            # Yanıt metni
            response_text = response.text
            print(f"Başarılı yanıt alındı, model: {self.model}")

            # Yanıtı ayrıştır
            return self._parse_response(response_text)

        except Exception as e:
            print(f"Gemini API hatası ({self.model}): {str(e)}")
            raise Exception(f"Gemini API hatası: {str(e)}")

    def _generate_with_ollama(self, system_prompt, user_prompt):
        """Ollama (yerel LLM) kullanarak kod üret"""
        headers = {'Content-Type': 'application/json'}
        data = {
            'model': self.ollama_model,
            'prompt': f"{system_prompt}\n\nUser prompt: {user_prompt}",
            'stream': False
        }

        response = requests.post(
            f"{self.ollama_base_url}/api/generate",
            headers=headers,
            data=json.dumps(data)
        )

        if response.status_code == 200:
            response_text = response.json().get('response', '')
            return self._parse_response(response_text)
        else:
            raise Exception(f"Ollama API hatası: {response.text}")

    def _parse_response(self, response_text):
        """
        LLM yanıtını ayrıştırarak başlık ve kodu çıkar.

        Parametreler:
            response_text (str): LLM'den gelen yanıtın parametresi

        Dönüş:
            tuple: (title, code) - Çıkarılan başlık ve kod
        """
        # Çıktı Başlığı
        title_prefix = "TITLE: "
        title = "Üretilen Python Kodu"  # Varsayılan başlık

        if title_prefix in response_text:
            title_line = next((line for line in response_text.split('\n')
                              if line.strip().startswith(title_prefix)), None)
            if title_line:
                title = title_line.replace(title_prefix, "").strip()

        # Kod Çıktısı
        code = ""
        in_code_block = False
        code_lines = []

        for line in response_text.split('\n'):
            if line.strip() == "```python" or line.strip() == "```":
                in_code_block = not in_code_block
                continue

            if in_code_block:
                code_lines.append(line)

        code = "\n".join(code_lines)

        return title, code
