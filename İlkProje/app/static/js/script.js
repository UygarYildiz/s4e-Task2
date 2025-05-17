document.addEventListener('DOMContentLoaded', function() {
    const promptForm = document.getElementById('prompt-form');
    const promptInput = document.getElementById('prompt');
    const generateBtn = document.getElementById('generate-btn');
    const loadingElement = document.getElementById('loading');
    const resultSection = document.getElementById('result-section');
    const codeTitleElement = document.getElementById('code-title');
    const codeOutputElement = document.getElementById('code-output');
    const copyBtn = document.getElementById('copy-btn');

    // Initialize highlight.js
    hljs.highlightAll();

    // Handle form submission
    promptForm.addEventListener('submit', async function(e) {
        e.preventDefault();

        const prompt = promptInput.value.trim();
        if (!prompt) {
            alert('Lütfen bir istek girin');
            return;
        }

        // Show loading indicator
        generateBtn.disabled = true;
        loadingElement.style.display = 'block';
        resultSection.style.display = 'none';

        try {
            const response = await fetch('/generate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ prompt })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Kod üretilirken hata oluştu');
            }

            const data = await response.json();

            // Update the UI with the generated code
            codeTitleElement.textContent = data.title;
            codeOutputElement.textContent = data.code;

            // Highlight the code
            hljs.highlightElement(codeOutputElement);

            // Show the result section
            resultSection.style.display = 'block';
        } catch (error) {
            alert(`Hata: ${error.message}`);
        } finally {
            // Hide loading indicator
            generateBtn.disabled = false;
            loadingElement.style.display = 'none';
        }
    });

    // Handle copy button click
    copyBtn.addEventListener('click', function() {
        const codeText = codeOutputElement.textContent;

        navigator.clipboard.writeText(codeText)
            .then(() => {
                // Change button text temporarily
                const originalText = copyBtn.textContent;
                copyBtn.textContent = 'Kopyalandı!';

                setTimeout(() => {
                    copyBtn.textContent = originalText;
                }, 2000);
            })
            .catch(err => {
                console.error('Kod kopyalanamadı:', err);
                alert('Kod panoya kopyalanamadı');
            });
    });
});
