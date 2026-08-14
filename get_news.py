import os
import requests
from supabase import create_client, Client
from dotenv import load_dotenv

# 1. .envファイルからAPIを読み込む
"""
ここは「The Guardian Open PlatformのAPI」と「SupabaseのAPI」，「Supabaseのurl」を取得する箇所．
APIはセキュリティの観点からGitHubに入れたときに見られないようにしなければならない．
そこでAPIなどをメモしたファイル「.env」を別に作成し，ここで参照するようにしている．
「.gitignore」に「.env」を記載したので，gitHubに「.env」が入れられることはない．
by小島
"""
load_dotenv()
GUARDIAN_API_KEY = os.environ.get("GUARDIAN_API_KEY")
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")

# 2. Supabaseに接続する
"""

"""
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY) #SupabaseのURLとKeyを使ってSupabaseにアクセスが可能なClientを作成した？by小島

def get_and_save_news():
    print("The Guardianからニュースを取得中...")
    
    url = f"https://content.guardianapis.com/search?api-key={GUARDIAN_API_KEY}&show-fields=bodyText"
    # The GuardianのURL．&show-fields=bodyTextによりニュース本文を取得することができる．by小島
    
    response = requests.get(url)
    # requestsは要求する，getはデータ取得．よってrequests.get(url)でurl内部のデータ取得を要求している．
    # その結果をresponseに格納しているby小島

    
    if response.status_code == 200:
        # 通信の結果が200であるかを確認する．（200は通信成功を意味する数字）by小島

        data = response.json()
        # The GuardianのJSON形式のデータをPythonの辞書型に変換してdataに格納by小島


        articles = data['response']['results']
        # 仕組みわからん

        print(f"{len(articles)}件のニュースが見つかりました。データベースに保存します...")
        # 取得したarticlesの数をカウントする
        
        for article in articles:
            fields = article.get('fields', {})
            body_text = fields.get('bodyText', '')
            
            
            news_data = {
                "title": article['webTitle'],
                "url": article['webUrl'],
                "content": body_text
            }
            
            try:
                supabase.table("news").insert(news_data).execute()

                
                print(f"保存成功: {news_data['title']}")
            except Exception as e:
                print(f"エラー: {e}")
                
        print("すべての処理が完了しました！")
    else:
        print("ニュースの取得に失敗しました。")
        print(f"原因コード: {response.status_code}")
        print(f"詳細メッセージ: {response.text}")

if __name__ == "__main__":
    get_and_save_news()