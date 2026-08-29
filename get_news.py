import os
import requests
from supabase import create_client, Client
from dotenv import load_dotenv

# Firebase関連はエラーになるため一時的にコメントアウトして無視します
# import firebase_admin
# from firebase_admin import credentials, messaging

# 1. .envファイルから秘密情報を読み込む
load_dotenv()
GUARDIAN_API_KEY = os.environ.get("GUARDIAN_API_KEY")
NEWSAPI_KEY = os.environ.get("NEWSAPI_KEY")
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")

# 2. Supabaseに接続する
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Firebaseの接続設定も無視します
# FIREBASE_CREDENTIALS_PATH = os.environ.get("FIREBASE_CREDENTIALS_PATH", "firebase-service-account.json")
# firebase_admin.initialize_app(credentials.Certificate(FIREBASE_CREDENTIALS_PATH))
# DAILY_NEWS_TOPIC = "daily_news"

def send_daily_notification():
    print("🔔 Firebase設定がないため、通知の送信はスキップします")
    pass

# --------------------------------------------------
# The Guardianから取得する関数
# --------------------------------------------------
def get_guardian_news():
    print("🌍 The Guardianからニュースを取得中...")
    
    url = f"https://content.guardianapis.com/search?api-key={GUARDIAN_API_KEY}&show-fields=bodyText,thumbnail"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        articles = data['response']['results']
        
        for article in articles:
            fields = article.get('fields', {})
            
            news_data = {
                "title": article.get('webTitle', ''),
                "url": article.get('webUrl', ''),
                "content": fields.get('bodyText', ''),
                "source": "The Guardian",
                "published_at": article.get('webPublicationDate'),
                "country": "GB",
                "thumbnail_url": fields.get('thumbnail', '')
            }
            
            try:
                supabase.table("news").insert(news_data).execute()
                print(f"✅ Guardian保存成功: {news_data['title']}")
            except Exception as e:
                print(f"❌ エラー: {e}")
    else:
        print("❌ Guardianの取得に失敗しました。")

# --------------------------------------------------
# 【修正版】NewsAPIから取得する関数（確実に国別に取得する）
# --------------------------------------------------
def get_newsapi_news(country_code="jp"):
    print(f"🌍 NewsAPIから国コード [{country_code.upper()}] のニュースを取得中...")
    
    # top-headlinesに変更し、countryを指定
    url = f"https://newsapi.org/v2/top-headlines?country={country_code}&apiKey={NEWSAPI_KEY}"
    
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        articles = data.get('articles', [])
        
        print(f"👀 NewsAPIで {len(articles)} 件のニュースが見つかりました！")
        
        # 最初の10件だけ保存
        for article in articles[:10]:
            content_text = article.get('content') or article.get('description') or ''
            
            news_data = {
                "title": article.get('title', ''),
                "url": article.get('url', ''),
                "content": content_text,
                "source": article.get('source', {}).get('name', 'NewsAPI'),
                "published_at": article.get('publishedAt'),
                # ANYではなく、指定した国コードを大文字にして保存
                "country": country_code.upper(),  
                "thumbnail_url": article.get('urlToImage', '')
            }
            
            try:
                supabase.table("news").insert(news_data).execute()
                print(f"✅ NewsAPI保存成功: {news_data['title']}")
            except Exception as e:
                print(f"❌ エラー: {e}")
    else:
        print("❌ NewsAPIの取得に失敗しました。")
        print(f"ステータスコード: {response.status_code}")
        print(f"詳細: {response.text}")

# --------------------------------------------------
# 実行部分
# --------------------------------------------------
if __name__ == "__main__":
    # Guardianのニュース取得（イギリス）
    get_guardian_news()

    print("-" * 40)

    # NewsAPIで色々な国のニュースを取得
    get_newsapi_news(country_code="jp") # 日本
    get_newsapi_news(country_code="us") # アメリカ
    get_newsapi_news(country_code="au") # オーストラリア

    print("-" * 40)

    # 通知送信（今回はスキップされます）
    send_daily_notification()

    print("🎉 すべての処理が完了しました！")