-- フレンドプロフィールで共有するピン留め・地図制覇状況の保存先。
-- Supabase Dashboard の SQL Editor で一度だけ実行する。

create table if not exists public.pinned_news (
  user_id uuid not null references public.profiles(id) on delete cascade,
  news_url text not null,
  title text not null,
  thumbnail_url text,
  source text,
  pinned_at timestamptz not null default now(),
  primary key (user_id, news_url)
);

create table if not exists public.visited_countries (
  user_id uuid not null references public.profiles(id) on delete cascade,
  country_code text not null,
  visited_at timestamptz not null default now(),
  primary key (user_id, country_code)
);

create index if not exists pinned_news_user_pinned_at_idx
  on public.pinned_news (user_id, pinned_at desc);
