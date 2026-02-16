insert into public.quest_defs (code, title, description, kind, target_count, is_active)
values
  ('daily_min3', '최소 완료', '카드 3개를 학습하세요', 'cards_done', 3, true),
  ('daily_10', '10카드 달성', '카드 10개를 학습하세요', 'cards_done', 10, true)
on conflict (code) do update
set title = excluded.title,
    description = excluded.description,
    kind = excluded.kind,
    target_count = excluded.target_count,
    is_active = excluded.is_active;

insert into public.content_items (kind, jlpt_level, jp, reading, meaning_ko, extra, is_active)
values
  ('vocab', 'N5', '学校', 'がっこう', '학교', '{}'::jsonb, true),
  ('vocab', 'N5', '友達', 'ともだち', '친구', '{}'::jsonb, true),
  ('vocab', 'N5', '先生', 'せんせい', '선생님', '{}'::jsonb, true),
  ('kana', 'N5', 'あ', 'a', '히라가나 a', '{}'::jsonb, true),
  ('vocab', 'N5', '日本語', 'にほんご', '일본어', '{}'::jsonb, true)
on conflict do nothing;
