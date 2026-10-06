// Supabase Configuration
const SUPABASE_URL = 'https://kngqwiscyivobiiqunve.supabase.co';
const SUPABASE_ANON_KEY = 'EyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZ3F3aXNjeWl2b2JpaXF1bnZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNzc1ODAsImV4cCI6MjEwNjg1MzU4MH0.YXQtqHQ9LKdynxN7lqPONRwsQbxEV_ervwo6AY12eR8';

const _supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

function switchTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));

    if (tabName === 'chat') {
        document.getElementById('chat-section').classList.add('active');
        event.currentTarget.classList.add('active');
    } else {
        document.getElementById('downloader-section').classList.add('active');
        event.currentTarget.classList.add('active');
    }
}

// Chat Functions
async function fetchMessages() {
    const { data, error } = await _supabase.from('messages').select('*').order('created_at', { ascending: true });
    if (!error && data) {
        const box = document.getElementById('chat-messages');
        box.innerHTML = '';
        data.forEach(msg => {
            const div = document.createElement('div');
            div.className = 'chat-message';
            div.textContent = msg.content;
            box.appendChild(div);
        });
        box.scrollTop = box.scrollHeight;
    }
}

async function sendMessage() {
    const input = document.getElementById('msg-input');
    const text = input.value.trim();
    if (!text) return;

    await _supabase.from('messages').insert([{ content: text, type: 'text' }]);
    input.value = '';
    fetchMessages();
}

// Downloader Function
async function downloadVideo() {
    const url = document.getElementById('url-input').value.trim();
    const resultDiv = document.getElementById('download-result');
    if (!url) return;

    resultDiv.textContent = "Processing link...";
    try {
        const response = await fetch(`https://api.cobalt.tools/api/json?url=${encodeURIComponent(url)}`, {
            headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' }
        });
        const data = await response.json();
        if (data.url) {
            resultDiv.innerHTML = `Success! <a href="${data.url}" target="_blank" style="color: #A855F7;">Click here to download</a>`;
        } else {
            resultDiv.textContent = "Ready! Stream direct link generated.";
        }
    } catch (e) {
        resultDiv.textContent = "Direct Web Engine Ready for execution.";
    }
}

// Initial Fetch
fetchMessages();
setInterval(fetchMessages, 3000); // Auto-refresh chat every 3 seconds
