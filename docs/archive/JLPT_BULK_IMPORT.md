# JLPT N5~N1 Bulk Import Guide (Supabase)

목표: N5~N1 단어를 Supabase `content_items`에 대량 저장하고 앱에서 레벨별로 조회.

## 1) 마이그레이션 실행
Supabase SQL Editor에서 아래 순서 실행:
1. `supabase/migrations/20260215103000_init.sql`
2. `supabase/migrations/20260215170000_add_onboarding_completed.sql`
3. `supabase/migrations/20260215183000_jlpt_import_pipeline.sql`

## 2) CSV 준비
헤더 형식(템플릿):
- `supabase/import_templates/jlpt_vocab_template.csv`

필수 컬럼:
- `jlpt_level` (N5~N1)
- `jp`
- `meaning_ko`

권장 컬럼:
- `reading`
- `kind` (`vocab` 권장)
- `is_active` (`true` 권장)

## 3) 스테이징 테이블로 CSV 업로드
Supabase Table Editor:
- 테이블 `import_jlpt_vocab` 선택
- Import data from CSV
- 준비한 CSV 업로드

이 레포에서 바로 생성한 파일:
- `supabase/import_ready/jlpt_vocab_n1_n5_from_downloads.csv`
- 생성 row: 8130
  - N1: 2699
  - N2: 1905
  - N3: 2140
  - N4: 668
  - N5: 718

## 4) 본 테이블 반영
SQL Editor에서 실행:

```sql
select * from public.import_jlpt_vocab_to_content(
  p_replace_duplicates := false,
  p_clear_staging_after := true
);
```

중복 레코드도 활성 상태로 갱신하려면:

```sql
select * from public.import_jlpt_vocab_to_content(
  p_replace_duplicates := true,
  p_clear_staging_after := true
);
```

## 5) 결과 확인
```sql
select jlpt_level, count(*)
from public.content_items
where kind = 'vocab' and is_active = true
group by jlpt_level
order by jlpt_level;
```

## 6) 앱에서 확인
- 콘텐츠 화면에서 레벨 칩(`N5`~`N1`)으로 필터 가능
- Supabase 연결 실행:

```bash
cd /Users/gaeng2y/Documents/github/study-jlpt/apps/mobile
flutter run \
  --dart-define=SUPABASE_URL=https://vdycpjdzsvwlnesujetm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```
