"""MEMORIA EXTERNA — shell Python/Streamlit y escritorio HTML/JS."""
from pathlib import Path
import json
import streamlit as st
import streamlit.components.v1 as components

st.set_page_config(page_title="MEMORIA EXTERNA", page_icon="🗂️", layout="wide", initial_sidebar_state="collapsed")
st.markdown("""<style>
#MainMenu,footer,header,[data-testid="stToolbar"]{visibility:hidden!important}
.block-container{padding:0!important;max-width:100%!important}
[data-testid="stAppViewContainer"]{background:#f4f4f1!important}
[data-testid="stVerticalBlock"]{gap:0!important}
iframe{display:block!important}
</style>""", unsafe_allow_html=True)

try:
    url = st.secrets.get("SUPABASE_URL", "")
    key = st.secrets.get("SUPABASE_ANON_KEY", "")
except Exception:
    url, key = "", ""
html = (Path(__file__).parent / 'component' / 'index.html').read_text(encoding='utf-8')
html = html.replace('__SUPABASE_CONFIG__', json.dumps({"url":url,"key":key}).replace('</','<\\/'))
components.html(html, height=920, scrolling=False)
