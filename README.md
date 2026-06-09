# Literaki API

Backend API dla gry typu Literaki / Scrabble. Projekt jest aplikacją Rails API-only, używa SQLite, JSON oraz wersjonowania endpointów przez `/api/v1`.

## Uruchomienie

```bash
bundle install
rails db:create db:migrate db:seed
bundle exec rspec
rails s
```

Domyślne bazy SQLite:

- development: `storage/development.sqlite3`
- test: `storage/test.sqlite3`

## Uruchomienie przez Docker Compose

Compose zakłada, że Traefik działa w osobnym projekcie Docker Compose i jest
podłączony do zewnętrznej sieci Docker o nazwie `proxy`.

```bash
docker network inspect proxy >/dev/null 2>&1 || docker network create proxy
export RAILS_MASTER_KEY='wartosc_z_config/master.key'
docker compose up -d --build
```

Aplikacja będzie wystawiona przez Traefika pod adresem:

```text
https://literaki.skiq.pl
```

Podgląd logów i zatrzymanie:

```bash
docker compose logs -f app
docker compose down
```

## Autoryzacja

Nie ma logowania emailem i hasłem. Klient tworzy sesję przez username, a API zwraca bezpieczny token. Kolejne requesty używają nagłówka:

```http
Authorization: Bearer TOKEN
```

Pełna dokumentacja kontraktów API znajduje się w [docs/API.md](docs/API.md).

## Panel administracyjny

Prosty, niezabezpieczony panel testowo-administracyjny jest dostępny pod:

```text
http://localhost:3000/admin
```

Panel pozwala podejrzeć użytkowników, tokeny, gry, graczy, racki, planszę, worek liter i historię ruchów. Jest przeznaczony do lokalnego testowania MVP.

## Przykłady curl

Utworzenie użytkownika przez username:

```bash
curl -s -X POST http://localhost:3000/api/v1/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"marek"}'
```

Użycie tokena i pobranie aktualnego użytkownika:

```bash
curl -s http://localhost:3000/api/v1/me \
  -H "Authorization: Bearer TOKEN"
```

Utworzenie gry:

```bash
curl -s -X POST http://localhost:3000/api/v1/games \
  -H "Authorization: Bearer TOKEN"
```

Dołączenie do gry:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/join \
  -H "Authorization: Bearer OPPONENT_TOKEN"
```

Start gry:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/start \
  -H "Authorization: Bearer TOKEN"
```

Wykonanie pass:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/moves \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"move_type":"pass"}'
```

Wykonanie place_tiles:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/moves \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"move_type":"place_tiles","tiles":[{"letter":"K","x":7,"y":7},{"letter":"O","x":8,"y":7},{"letter":"T","x":9,"y":7}]}'
```

Pobranie stanu gry:

```bash
curl -s http://localhost:3000/api/v1/games/1 \
  -H "Authorization: Bearer TOKEN"
```

## Endpointy

- `POST /api/v1/auth`
- `GET /api/v1/me`
- `GET /api/v1/games`
- `POST /api/v1/games`
- `GET /api/v1/games/:id`
- `POST /api/v1/games/:id/join`
- `POST /api/v1/games/:id/start`
- `GET /api/v1/games/:game_id/moves`
- `POST /api/v1/games/:game_id/moves`
- `GET /admin`
- `GET /admin/games/:id`

## Zasady MVP

- Plansza ma rozmiar 15x15.
- Gra ma maksymalnie 2 graczy.
- Ruch może wykonać tylko aktualny gracz.
- Rack ma 7 liter i po ruchu jest uzupełniany z worka.
- `place_tiles` liczy punkty jako sumę wartości położonych liter.
- `place_tiles` wylicza słowa z planszy i odrzuca ruch, jeśli któregokolwiek słowa nie ma w tabeli `words`.
- Rack przeciwnika nie jest zwracany w odpowiedziach API.
- Klient nie jest źródłem prawdy dla wyniku, tury ani zwycięzcy.
