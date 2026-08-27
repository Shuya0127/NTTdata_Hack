-- FCMデバイストークンの保存(1ユーザーが複数端末を持てるようテーブル分離)
create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  token text not null,
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

-- 重複送信防止用の「送信済みフラグ」を既存テーブルに追加
alter table news_likes add column if not exists pushed boolean not null default false;
alter table news_comments add column if not exists pushed boolean not null default false;
alter table friendships add column if not exists pushed boolean not null default false;
