# S4E tarafından sağlanan örnek  Task  ve Job sınıfları
class Task:
    """
    Task sınıfı için yer tutucu.
    Gerçek uygulamada s4e.task modülünden import edilmelidir.
    """
    def __init__(self):
        self.asset = {}
        self.param = {'max_score': 10}
        self.output = {}
        self.score = 0

class Job(Task):
    """
    S4E tarafından sağlanan Job sınıfı.
    Bu sınıf, Task sınıfından türetilmiştir ve yapay zeka tarafından üretilen kod için şablon olarak kullanılır.
    """
    def run(self):
        """
        İşi çalıştır ve sonuçları output sözlüğüne kaydet.
        Bu metod alt sınıflar tarafından geçersiz kılınmalıdır.
        """
        asset = self.asset
        self.output['detail'] = []  # İşten gelen detaylı sonuç
        self.output['compact'] = []  # İşten gelen kısa sonuç
        self.output['video'] = []  # İşi yapmak için adımlar, komutlar vb.

    def calculate_score(self):
        """
        İşin skorunu hesapla.
        Skor 0 ile 10 arasında bir sayıdır:
        - score == 1: bilgi
        - 1 < score < 4: düşük
        - 4 <= score < 7: orta
        - 7 <= score < 9: yüksek
        - 9 <= score < 11: kritik
        """
        # Anlamlı bir skora ayarla
        self.score = self.param['max_score']

    def __str__(self):
        return f"Job(score={self.score})"
