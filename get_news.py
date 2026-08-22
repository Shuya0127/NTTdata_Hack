import os
import requests
from supabase import create_client, Client
from dotenv import load_dotenv

# 1. .envファイルから秘密情報を読み込む
load_dotenv()
GUARDIAN_API_KEY = os.environ.get("GUARDIAN_API_KEY")
NEWSAPI_KEY = os.environ.get("NEWSAPI_KEY")
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")

# 2. Supabaseに接続する
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --------------------------------------------------
# The Guardianから取得する関数
# --------------------------------------------------
def get_guardian_news():
    print("🌍 The Guardianからニュースを取得中...")
    
    # 【変更点】show-fieldsに「thumbnail」を追加しました
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
                "thumbnail_url": fields.get('thumbnail', '')  # 【追加】サムネイル画像URL
            }
            
            try:
                supabase.table("news").insert(news_data).execute()
                print(f"✅ Guardian保存成功: {news_data['title']}")
            except Exception as e:
                print(f"❌ エラー: {e}")
    else:
        print("❌ Guardianの取得に失敗しました。")

# --------------------------------------------------
# 【修正版】NewsAPIから取得する関数（確実に取得する）
# --------------------------------------------------
def get_newsapi_news(keyword="japan"):
    print(f"🌍 NewsAPIからキーワード [{keyword}] のニュースを取得中...")
    
    # 【変更点】top-headlinesではなく、everythingに変更してキーワードで検索
    url = f"https://newsapi.org/v2/everything?q={keyword}&sortBy=publishedAt&apiKey={NEWSAPI_KEY}"
    
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        articles = data.get('articles', [])
        
        # 【追加】何件見つかったか分かりやすくprintで表示する
        print(f"👀 NewsAPIで {len(articles)} 件のニュースが見つかりました！")
        
        # 取得件数が多いと時間がかかるので、最初の10件だけ保存するように制限（お好みで変更してください）
        for article in articles[:10]:
            content_text = article.get('content') or article.get('description') or ''
            
            news_data = {
                "title": article.get('title', ''),
                "url": article.get('url', ''),
                "content": content_text,
                "source": article.get('source', {}).get('name', 'NewsAPI'),
                "published_at": article.get('publishedAt'),
                "country": "ANY",  # everythingエンドポイントには国指定がないため、ANYとしておきます
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
        print(f"詳細: {response.text}") # エラーの詳細も表示するようにしました
# --------------------------------------------------
# 実行部分
# --------------------------------------------------
if __name__ == "__main__":
    # Guardianのニュース取得
    get_guardian_news()
    
    print("-" * 40)
    
    # 【修正】引数を keyword に変更します
    get_newsapi_news(keyword="japan")
    
    # ちなみに、keyword="technology" や keyword="anime" などに変えれば、
    # 好きなジャンルのニュースを取ってくることもできます！
    
    print("🎉 すべての処理が完了しました！")