# Отчёт о дублировании: домены и IP-списки

Проверены все указанные списки (`.srs` декомпилированы через `sing-box rule-set decompile`), а также отдельные домены и IP из задания. Проверялись три вида дублей: точные совпадения, поглощение домена более широким суффиксом и вложенность подсетей (CIDR внутри большего CIDR).

## 1. Размер каждого источника

| Источник | Домены | IP-CIDR |
|---|--:|--:|
| `cloudflare.srs` | 4 | 15 |
| `cloudfront.srs` | 1 | 179 |
| `digitalocean.srs` | 1 | 164 |
| `discord.srs` | 20 | 8 |
| `google_ai.srs` | 28 | 0 |
| `google_play.srs` | 12 | 0 |
| `hetzner.srs` | 1 | 79 |
| `hodca.srs` | 250 | 0 |
| `podkop-foreign-domains.lst` | 1417 | 0 |
| `podkop-foreign-subnets.lst` | 0 | 10498 |
| `russia_inside.srs` | 1183 | 0 |
| `telegram-ipv4.lst` | 0 | 10 |
| `twitch-ad-bypass.srs` | 4 | 0 |
| `whatsapp-cidr_ipv4.txt` | 0 | 15 |
| `whatsapp-domains.txt` | 4 | 0 |

**Дублей внутри одного файла нет** — в каждом `.lst`/`.txt` число строк = числу уникальных значений.

## 2. Отдельные домены из задания (13 шт.)

✅ **Ни один из 13 доменов не дублируется** ни с одним списком — все уникальны:

`senko.digital`, `gammafun.com`, `moontontech.com`, `hihonorcloud.com`, `hihonor.com`, `aihelp.net`, `catdelta.com`, `bytegsdk.com`, `bytepluses.com`, `mossfast.com`, `oveg.ru`, `audioknigi.xyz`, `eurogamer.net`

## 3. Отдельные IP/подсети из задания (5 шт.)

- ⚠️ `91.108.0.0/16` — **пересекается**: эта подсеть СОДЕРЖИТ 9 уже имеющихся записей из `podkop-foreign-subnets.lst`, `telegram-ipv4.lst`:
  - `91.108.8.0/21`, `91.108.16.0/21`, `91.108.4.0/22`, `91.108.8.0/22`, `91.108.12.0/22`, `91.108.16.0/22`, `91.108.20.0/22`, `91.108.36.0/22`, `91.108.56.0/22`
- ✅ `74.125.250.0/24` — уникален, пересечений с списками нет
- ✅ `74.125.247.128/32` — уникален, пересечений с списками нет
- ✅ `184.66.194.18` — уникален, пересечений с списками нет
- ✅ `93.189.201.43` — уникален, пересечений с списками нет

## 4. Пересечения доменов между списками

### 4.1. Точные совпадения имён — пары источников

| Кол-во общих | Источник A | Источник B |
|--:|---|---|
| 249 | `hodca.srs` | `podkop-foreign-domains.lst` |
| 84 | `podkop-foreign-domains.lst` | `russia_inside.srs` |
| 20 | `discord.srs` | `russia_inside.srs` |
| 10 | `hodca.srs` | `russia_inside.srs` |
| 4 | `cloudflare.srs` | `podkop-foreign-domains.lst` |
| 2 | `russia_inside.srs` | `twitch-ad-bypass.srs` |
| 1 | `russia_inside.srs` | `whatsapp-domains.txt` |
| 1 | `podkop-foreign-domains.lst` | `whatsapp-domains.txt` |
| 1 | `hetzner.srs` | `russia_inside.srs` |
| 1 | `hetzner.srs` | `podkop-foreign-domains.lst` |
| 1 | `hetzner.srs` | `hodca.srs` |
| 1 | `google_ai.srs` | `russia_inside.srs` |
| 1 | `digitalocean.srs` | `russia_inside.srs` |
| 1 | `digitalocean.srs` | `podkop-foreign-domains.lst` |
| 1 | `cloudfront.srs` | `podkop-foreign-domains.lst` |
| 1 | `cloudfront.srs` | `hodca.srs` |
| 1 | `cloudflare.srs` | `hodca.srs` |

Всего доменных имён, встречающихся более чем в одном источнике: **349**.

### 4.2. Поглощение суффиксом — **300** имён покрыты более широким суффиксом из другого места

Примеры (имя ⊂ суффикс):

- `2fa.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `a.claude.ai` (podkop-foreign-domains.lst) ⊂ `claude.ai` (podkop-foreign-domains.lst, russia_inside.srs)
- `ab.chatgpt.com` (podkop-foreign-domains.lst) ⊂ `chatgpt.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `abtest-sg-tiktok.byteoversea.com` (podkop-foreign-domains.lst) ⊂ `byteoversea.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `abtest-va-tiktok.byteoversea.com` (podkop-foreign-domains.lst) ⊂ `byteoversea.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `abuse.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `account.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `admin.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `alpha.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `analytics.facebook.com` (podkop-foreign-domains.lst) ⊂ `facebook.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `analytics.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `analytics.tiktok.com` (podkop-foreign-domains.lst) ⊂ `tiktok.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `android.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `anthropic.qualtrics.com` (russia_inside.srs) ⊂ `qualtrics.com` (hodca.srs, podkop-foreign-domains.lst)
- `api-docs.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `api.anthropic.com` (podkop-foreign-domains.lst) ⊂ `anthropic.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `api.openai.com` (podkop-foreign-domains.lst) ⊂ `openai.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `api.t.me` (podkop-foreign-domains.lst) ⊂ `t.me` (podkop-foreign-domains.lst)
- `api.telegram.com` (podkop-foreign-domains.lst) ⊂ `telegram.com` (podkop-foreign-domains.lst)
- `api.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `api.themoviedb.org` (russia_inside.srs) ⊂ `themoviedb.org` (russia_inside.srs)
- `api1.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `api2.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `api3.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `apollo.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `ares.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `assets.claude.ai` (podkop-foreign-domains.lst) ⊂ `claude.ai` (podkop-foreign-domains.lst, russia_inside.srs)
- `assets.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `athena.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `aurora.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `auth-cdn.oaistatic.com` (podkop-foreign-domains.lst) ⊂ `oaistatic.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `auth.openai.com` (podkop-foreign-domains.lst) ⊂ `openai.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `auth.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `auth.windsurf.com` (podkop-foreign-domains.lst) ⊂ `windsurf.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `b.whatsapp.com` (whatsapp-domains.txt) ⊂ `whatsapp.com` (podkop-foreign-domains.lst, russia_inside.srs, whatsapp-domains.txt)
- `backend-v2.crixet.com` (russia_inside.srs) ⊂ `crixet.com` (podkop-foreign-domains.lst)
- `bds-sg.byteoversea.com` (podkop-foreign-domains.lst) ⊂ `byteoversea.com` (podkop-foreign-domains.lst, russia_inside.srs)
- `beta.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `blog.telegram.org` (podkop-foreign-domains.lst) ⊂ `telegram.org` (podkop-foreign-domains.lst)
- `bot.t.me` (podkop-foreign-domains.lst) ⊂ `t.me` (podkop-foreign-domains.lst)
- … и ещё 260

## 5. Пересечения IP между списками

### 5.1. Точные совпадения CIDR — пары источников

| Кол-во общих | Источник A | Источник B |
|--:|---|---|
| 164 | `digitalocean.srs` | `podkop-foreign-subnets.lst` |
| 160 | `cloudfront.srs` | `podkop-foreign-subnets.lst` |
| 79 | `hetzner.srs` | `podkop-foreign-subnets.lst` |
| 15 | `cloudflare.srs` | `podkop-foreign-subnets.lst` |
| 12 | `podkop-foreign-subnets.lst` | `whatsapp-cidr_ipv4.txt` |
| 6 | `podkop-foreign-subnets.lst` | `telegram-ipv4.lst` |
| 3 | `discord.srs` | `podkop-foreign-subnets.lst` |
| 2 | `cloudflare.srs` | `discord.srs` |

Всего CIDR, встречающихся более чем в одном источнике: **437**.

**Вывод по IP:** провайдерские `.srs` практически полностью входят в `podkop-foreign-subnets.lst`:

- `digitalocean.srs`: 164 из 164 CIDR уже есть в `podkop-foreign-subnets.lst`
- `cloudfront.srs`: 160 из 179 CIDR уже есть в `podkop-foreign-subnets.lst`
- `hetzner.srs`: 79 из 79 CIDR уже есть в `podkop-foreign-subnets.lst`
- `cloudflare.srs`: 15 из 15 CIDR уже есть в `podkop-foreign-subnets.lst`
- `whatsapp-cidr_ipv4.txt`: 12 из 15 уже в podkop
- `telegram-ipv4.lst`: 6 из 10 уже в podkop

### 5.2. Вложенные подсети — **4033** CIDR являются подсетью большего CIDR в наборе (с учётом точных дублей).

## 6. Итог и рекомендации

- ✅ Внутренних дублей в самих файлах нет.
- ✅ Все 13 отдельных доменов уникальны — можно добавлять.
- ⚠️ Из 5 отдельных IP: `91.108.0.0/16` (Telegram) пересекается с подсетями из `telegram-ipv4.lst` и `podkop-foreign-subnets.lst` (поглощает их). Остальные 4 IP уникальны.
- ⚠️ Сильное дублирование доменов между `hodca.srs` ↔ `podkop-foreign-domains.lst` (249) и `podkop-foreign-domains.lst` ↔ `russia_inside.srs` (84); `discord.srs` ⊂ `russia_inside.srs` (20).
- ⚠️ По IP провайдерские списки (`digitalocean/cloudfront/hetzner/cloudflare.srs`) почти целиком дублируются `podkop-foreign-subnets.lst` — при совместном использовании их можно не подключать.

## 7. Сравнение с `mudachyo/IP-Ranger` → `all-in-one.srs`

`all-in-one.srs` — это **только IP** (доменов нет): **17 376 CIDR**. Сравнение со всеми IP-источниками (учитывались точные совпадения и вложенность подсетей):

| Источник | Всего CIDR | Точно в AIO | Вложено в больший AIO | Покрыто | Не покрыто |
|---|--:|--:|--:|--:|--:|
| `digitalocean.srs` | 164 | 154 | 10 | **100 %** | 0 |
| `hetzner.srs` | 79 | 77 | 2 | **100 %** | 0 |
| `podkop-foreign-subnets.lst` | 10 498 | 1 096 | 7 192 | **78.9 %** | 2 210 |
| `cloudfront.srs` | 179 | 2 | 123 | 69.8 % | 54 |
| `cloudflare.srs` | 15 | 4 | 0 | 26.7 % | 11 |
| `telegram-ipv4.lst` | 10 | 0 | 0 | **0 %** | 10 |
| `whatsapp-cidr_ipv4.txt` | 15 | 0 | 0 | **0 %** | 15 |
| `discord.srs` | 8 | 0 | 0 | **0 %** | 8 |

**`all-in-one` ↔ `podkop-foreign-subnets`** (два самых крупных IP-набора):

- 8 288 из 10 498 (79 %) подсетей podkop уже покрыты all-in-one;
- но только 2 792 из 17 376 (16 %) all-in-one покрыты podkop → у all-in-one ~14,5 тыс. диапазонов, которых нет в podkop. Списки сильно пересекаются, но взаимно НЕ являются подмножеством.

**Отдельные IP из задания vs `all-in-one`:**

- ⚠️ `74.125.250.0/24` и `74.125.247.128/32` (Google) — **оба покрыты** подсетью `74.125.0.0/16` из all-in-one (в исходных списках их не было, а здесь они избыточны).
- ✅ `91.108.0.0/16`, `184.66.194.18`, `93.189.201.43` — в all-in-one отсутствуют.

**Вывод:** `all-in-one.srs` — это крупный агрегатор IP, который полностью поглощает `digitalocean.srs` и `hetzner.srs`, в значительной мере `cloudfront.srs` и большую часть `podkop-foreign-subnets.lst`. Но он **не содержит** Telegram (`91.108.*`, `telegram-ipv4.lst`), WhatsApp и Discord-подсети — эти списки нужно подключать отдельно. Доменные списки он не покрывает вообще.
