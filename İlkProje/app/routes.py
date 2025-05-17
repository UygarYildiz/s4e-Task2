from flask import Blueprint, render_template, request, jsonify
from app.llm import LLMService

main = Blueprint('main', __name__)
llm_service = LLMService()

@main.route('/')
def index():
    """Ana sayfayı istek formu ile görüntüle."""
    return render_template('index.html')

@main.route('/generate', methods=['POST'])
def generate_code():
    """
    Kullanıcının isteğine göre kod üret.

    Dönüş:
        Üretilen başlık ve kodu içeren JSON yanıtı
    """
    data = request.get_json()
    prompt = data.get('prompt', '')

    if not prompt:
        return jsonify({'error': 'İstek gereklidir'}), 400

    try:
        title, code = llm_service.generate_code(prompt)
        return jsonify({
            'title': title,
            'code': code
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
