import os
from supabase import create_client, Client
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, messaging

# 1. .envファイルから秘密情報を読み込む
load_dotenv()
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
FIREBASE_CREDENTIALS_PATH = os.environ.get(
    "FIREBASE_CREDENTIALS_PATH", "firebase-service-account.json"
)

# 2. Supabaseに接続する
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 3. Firebaseに接続する(通知送信用)
firebase_admin.initialize_app(
    credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
)


def get_tokens(user_id):
    """指定ユーザーの全端末のFCMトークンを取得する"""
    rows = (
        supabase.table("device_tokens")
        .select("token")
        .eq("user_id", user_id)
        .execute()
        .data
    )
    return [row["token"] for row in rows]


def get_username(user_id):
    """profilesテーブルからユーザー名を取得する"""
    rows = (
        supabase.table("profiles")
        .select("username")
        .eq("id", user_id)
        .execute()
        .data
    )
    return rows[0]["username"] if rows else "ユーザー"


def send_push(token, title, body):
    try:
        messaging.send(
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                token=token,
            )
        )
        print(f"✅ 送信成功: {title} -> {token[:12]}...")
    except Exception as e:
        print(f"❌ 送信失敗: {e}")


def notify_user(user_id, title, body):
    tokens = get_tokens(user_id)
    if not tokens:
        print(f"⚠️ ユーザー {user_id} の端末トークンが見つかりません")
        return
    for token in tokens:
        send_push(token, title, body)


def process_likes():
    print("👍 いいね通知を確認中...")
    likes = (
        supabase.table("news_likes")
        .select("id, user_read_news_id, user_id")
        .eq("pushed", False)
        .execute()
        .data
    )

    for like in likes:
        history_rows = (
            supabase.table("user_read_news")
            .select("user_id")
            .eq("id", like["user_read_news_id"])
            .execute()
            .data
        )
        if history_rows and history_rows[0]["user_id"] != like["user_id"]:
            owner_id = history_rows[0]["user_id"]
            liker_name = get_username(like["user_id"])
            notify_user(
                owner_id,
                "いいねが届きました",
                f"{liker_name}さんがあなたの投稿にいいねしました",
            )

        supabase.table("news_likes").update({"pushed": True}).eq(
            "id", like["id"]
        ).execute()


def process_comments():
    print("💬 コメント通知を確認中...")
    comments = (
        supabase.table("news_comments")
        .select("id, user_read_news_id, user_id, comment")
        .eq("pushed", False)
        .execute()
        .data
    )

    for comment in comments:
        history_rows = (
            supabase.table("user_read_news")
            .select("user_id")
            .eq("id", comment["user_read_news_id"])
            .execute()
            .data
        )
        if history_rows and history_rows[0]["user_id"] != comment["user_id"]:
            owner_id = history_rows[0]["user_id"]
            commenter_name = get_username(comment["user_id"])
            text = comment["comment"] or ""
            excerpt = text if len(text) <= 40 else text[:40] + "..."
            notify_user(
                owner_id,
                "コメントが届きました",
                f"{commenter_name}さん: {excerpt}",
            )

        supabase.table("news_comments").update({"pushed": True}).eq(
            "id", comment["id"]
        ).execute()


def process_friend_requests():
    print("🧑‍🤝‍🧑 フレンド申請通知を確認中...")
    requests_rows = (
        supabase.table("friendships")
        .select("id, sender_id, receiver_id")
        .eq("status", "pending")
        .eq("pushed", False)
        .execute()
        .data
    )

    for request in requests_rows:
        sender_name = get_username(request["sender_id"])
        notify_user(
            request["receiver_id"],
            "フレンド申請が届きました",
            f"{sender_name}さんからフレンド申請が届いています",
        )

        supabase.table("friendships").update({"pushed": True}).eq(
            "id", request["id"]
        ).execute()


if __name__ == "__main__":
    process_likes()
    process_comments()
    process_friend_requests()
    print("🎉 すべての通知処理が完了しました！")
