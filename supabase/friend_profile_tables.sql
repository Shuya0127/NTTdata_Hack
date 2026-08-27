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

alter table public.pinned_news enable row level security;
alter table public.visited_countries enable row level security;

drop policy if exists "Users can view own pins" on public.pinned_news;
create policy "Users can view own pins"
  on public.pinned_news for select
  using (auth.uid() = user_id);

drop policy if exists "Friends can view each other's pins" on public.pinned_news;
create policy "Friends can view each other's pins"
  on public.pinned_news for select
  using (
    exists (
      select 1
      from public.friendships f
      where (
        (f.sender_id = auth.uid() and f.receiver_id = user_id)
        or (f.receiver_id = auth.uid() and f.sender_id = user_id)
      )
      and f.status = 'accepted'
    )
  );

drop policy if exists "Users can insert own pins" on public.pinned_news;
create policy "Users can insert own pins"
  on public.pinned_news for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own pins" on public.pinned_news;
create policy "Users can update own pins"
  on public.pinned_news for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own pins" on public.pinned_news;
create policy "Users can delete own pins"
  on public.pinned_news for delete
  using (auth.uid() = user_id);

drop policy if exists "Users can view own visited countries" on public.visited_countries;
create policy "Users can view own visited countries"
  on public.visited_countries for select
  using (auth.uid() = user_id);

drop policy if exists "Friends can view each other's visited countries" on public.visited_countries;
create policy "Friends can view each other's visited countries"
  on public.visited_countries for select
  using (
    exists (
      select 1
      from public.friendships f
      where (
        (f.sender_id = auth.uid() and f.receiver_id = user_id)
        or (f.receiver_id = auth.uid() and f.sender_id = user_id)
      )
      and f.status = 'accepted'
    )
  );

drop policy if exists "Users can insert own visited countries" on public.visited_countries;
create policy "Users can insert own visited countries"
  on public.visited_countries for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own visited countries" on public.visited_countries;
create policy "Users can delete own visited countries"
  on public.visited_countries for delete
  using (auth.uid() = user_id);
