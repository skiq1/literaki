# Literaki API Documentation

Dokument opisuje publiczne endpointy JSON API oraz pomocniczy panel HTML dla testowania i administracji MVP.

## Zasady Ogólne

Base URL lokalnie:

```text
http://localhost:3000
```

Wersja API:

```text
/api/v1
```

Format danych:

```http
Content-Type: application/json
Accept: application/json
```

Autoryzacja dla endpointów wymagających użytkownika:

```http
Authorization: Bearer <token>
```

Token jest generowany przez backend w `POST /api/v1/auth`. Username jest wyłącznie nazwą wyświetlaną i nie jest credentialem. Każde poprawne wywołanie `POST /api/v1/auth` może utworzyć nowego użytkownika z nowym tokenem.

## Format Błędów

Brak autoryzacji:

```json
{
  "error": "Unauthorized"
}
```

Błędy walidacji, ruchów i reguł gry:

```json
{
  "errors": ["message 1", "message 2"]
}
```

Typowe statusy:

- `200 OK` dla poprawnych odczytów i akcji bez tworzenia głównego zasobu.
- `201 Created` dla utworzenia sesji, gry lub ruchu.
- `401 Unauthorized` dla braku lub niepoprawnego tokena.
- `403 Forbidden` dla próby dostępu do gry, w której użytkownik nie jest graczem.
- `404 Not Found` dla nieistniejącego zasobu.
- `422 Unprocessable Content` dla błędów walidacji lub niepoprawnych reguł gry.

## Obiekty Odpowiedzi

### User Auth

```json
{
  "id": 1,
  "username": "marek"
}
```

### Current User

```json
{
  "id": 1,
  "username": "marek",
  "games_played": 0,
  "games_won": 0,
  "total_score": 0
}
```

### Game

```json
{
  "id": 1,
  "status": "active",
  "board": {
    "7,7": "K",
    "8,7": "O",
    "9,7": "T"
  },
  "players": [
    {
      "id": 1,
      "username": "marek",
      "score": 5,
      "position": 1,
      "passed_turns_count": 0,
      "rack": ["A", "E", "R", "S", "Z", "W", "Y"]
    },
    {
      "id": 2,
      "username": "ania",
      "score": 0,
      "position": 2,
      "passed_turns_count": 0
    }
  ],
  "current_turn_user_id": 2,
  "winner_id": null,
  "started_at": "2026-05-25T12:00:00.000Z",
  "finished_at": null,
  "moves": []
}
```

`rack` jest zwracany tylko dla aktualnie autoryzowanego użytkownika. Rack przeciwnika nie jest ujawniany w API.

### Move

```json
{
  "id": 1,
  "game_id": 1,
  "user_id": 1,
  "move_type": "place_tiles",
  "tiles": [
    { "letter": "K", "x": 7, "y": 7 }
  ],
  "words": [],
  "score": 2,
  "created_at": "2026-05-25T12:00:00.000Z"
}
```

## POST /api/v1/auth

Tworzy użytkownika i zwraca token API. Endpoint nie loguje po username i nie próbuje wyszukiwać istniejącej tożsamości po username.

Autoryzacja: nie wymaga.

Request:

```json
{
  "username": "marek"
}
```

Response `201 Created`:

```json
{
  "user": {
    "id": 1,
    "username": "marek"
  },
  "token": "generated_secure_token"
}
```

Błędy:

- `422` gdy `username` jest pusty.

Przykład:

```bash
curl -s -X POST http://localhost:3000/api/v1/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"marek"}'
```

## GET /api/v1/me

Zwraca aktualnego użytkownika zidentyfikowanego przez token.

Autoryzacja: wymaga.

Response `200 OK`:

```json
{
  "id": 1,
  "username": "marek",
  "games_played": 0,
  "games_won": 0,
  "total_score": 0
}
```

Błędy:

- `401` gdy brakuje tokena lub token jest niepoprawny.

Przykład:

```bash
curl -s http://localhost:3000/api/v1/me \
  -H "Authorization: Bearer TOKEN"
```

## GET /api/v1/games

Zwraca listę gier, w których uczestniczy aktualny użytkownik.

Autoryzacja: wymaga.

Response `200 OK`:

```json
[
  {
    "id": 1,
    "status": "waiting",
    "board": {},
    "players": [
      {
        "id": 1,
        "username": "marek",
        "score": 0,
        "position": 1,
        "passed_turns_count": 0,
        "rack": []
      }
    ],
    "current_turn_user_id": null,
    "winner_id": null,
    "started_at": null,
    "finished_at": null,
    "moves": []
  }
]
```

Błędy:

- `401` gdy brakuje tokena lub token jest niepoprawny.

## POST /api/v1/games

Tworzy nową grę w statusie `waiting` i dodaje aktualnego użytkownika jako pierwszego gracza.

Autoryzacja: wymaga.

Request: pusty body lub JSON. Pole `opponent_username` nie jest używane w MVP, ponieważ drugi gracz dołącza przez osobny endpoint.

```json
{}
```

Response `201 Created`: obiekt `Game`.

Błędy:

- `401` gdy brakuje tokena lub token jest niepoprawny.
- `422` dla błędów zapisu gry lub gracza.

Przykład:

```bash
curl -s -X POST http://localhost:3000/api/v1/games \
  -H "Authorization: Bearer TOKEN"
```

## GET /api/v1/games/:id

Zwraca pełny stan gry dla uczestnika gry.

Autoryzacja: wymaga.

Response `200 OK`: obiekt `Game`.

Błędy:

- `401` gdy brakuje tokena lub token jest niepoprawny.
- `403` gdy użytkownik nie jest graczem w tej grze.
- `404` gdy gra nie istnieje.

Przykład:

```bash
curl -s http://localhost:3000/api/v1/games/1 \
  -H "Authorization: Bearer TOKEN"
```

## POST /api/v1/games/:id/join

Dołącza aktualnego użytkownika do gry w statusie `waiting`.

Autoryzacja: wymaga.

Request:

```json
{}
```

Response `200 OK`: obiekt `Game`.

Reguły:

- Gra musi mieć status `waiting`.
- Gra może mieć maksymalnie 2 graczy.
- Ten sam użytkownik nie może dołączyć drugi raz do tej samej gry.

Błędy:

- `401` gdy brakuje tokena lub token jest niepoprawny.
- `404` gdy gra nie istnieje.
- `422` gdy gra nie jest `waiting`, ma już 2 graczy lub użytkownik już dołączył.

Przykład:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/join \
  -H "Authorization: Bearer OPPONENT_TOKEN"
```

## POST /api/v1/games/:id/start

Startuje grę, generuje worek liter, rozdaje każdemu graczowi po 7 liter, ustawia pustą planszę i pierwszą turę.

Autoryzacja: wymaga. Aktualny użytkownik musi być graczem w tej grze.

Request:

```json
{}
```

Response `200 OK`: obiekt `Game`.

Reguły:

- Gra musi mieć status `waiting`.
- Gra musi mieć dokładnie 2 graczy.
- `started_at` jest ustawiane przez backend.
- `current_turn_user_id` jest ustawiane przez backend.

Błędy:

- `401` gdy brakuje tokena lub token jest niepoprawny.
- `403` gdy użytkownik nie jest graczem w tej grze.
- `404` gdy gra nie istnieje.
- `422` gdy gra nie spełnia warunków startu.

Przykład:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/start \
  -H "Authorization: Bearer TOKEN"
```

## GET /api/v1/games/:game_id/moves

Zwraca historię ruchów gry.

Autoryzacja: wymaga. Aktualny użytkownik musi być graczem w tej grze.

Response `200 OK`:

```json
[
  {
    "id": 1,
    "game_id": 1,
    "user_id": 1,
    "move_type": "pass",
    "tiles": [],
    "words": [],
    "score": 0,
    "created_at": "2026-05-25T12:00:00.000Z"
  }
]
```

Błędy:

- `401` gdy brakuje tokena lub token jest niepoprawny.
- `403` gdy użytkownik nie jest graczem w tej grze.
- `404` gdy gra nie istnieje.

## POST /api/v1/games/:game_id/moves

Tworzy ruch w aktywnej grze. Punktacja, zmiana tury, aktualizacja racka, planszy i worka są wykonywane przez backend w transakcji.

Autoryzacja: wymaga. Aktualny użytkownik musi być graczem i musi mieć aktualną turę.

Wspólne reguły:

- Gra musi mieć status `active`.
- Ruch może wykonać tylko `current_turn_user_id`.
- Klient nie może decydować o `score`, `winner_id` ani `current_turn_user_id`.
- Po ruchu tura przechodzi na drugiego gracza, z wyjątkiem zakończenia gry przez `resign`.

Błędy wspólne:

- `401` gdy brakuje tokena lub token jest niepoprawny.
- `403` gdy użytkownik nie jest graczem w tej grze.
- `404` gdy gra nie istnieje.
- `422` gdy gra nie jest aktywna, nie jest tura użytkownika lub ruch jest niepoprawny.

### pass

Pomija turę gracza.

Request:

```json
{
  "move_type": "pass"
}
```

Response `201 Created`: obiekt `Move` z `move_type: "pass"` i `score: 0`.

Przykład:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/moves \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"move_type":"pass"}'
```

### resign

Kończy grę przez poddanie się aktualnego gracza. Zwycięzcą zostaje drugi gracz.

Request:

```json
{
  "move_type": "resign"
}
```

Response `201 Created`: obiekt `Move` z `move_type: "resign"`.

Efekty:

- `game.status` zmienia się na `finished`.
- `winner_id` wskazuje przeciwnika.
- `finished_at` jest ustawiane przez backend.
- Statystyki graczy są aktualizowane.

### exchange_tiles

Wymienia wskazane litery z racka gracza.

Request:

```json
{
  "move_type": "exchange_tiles",
  "tiles": ["A", "E", "R"]
}
```

Response `201 Created`: obiekt `Move`.

Reguły:

- `tiles` nie może być puste.
- Gracz może wymienić tylko litery, które ma na racku.
- Backend dobiera tyle liter z worka, ile gracz wymienia, a oddane litery wracają do worka.

Błędy specyficzne:

- `422` z `"Tiles can't be blank"`.
- `422` z `"Rack does not include all requested tiles"`.

### place_tiles

Kładzie litery na planszy i nalicza punkty jako sumę wartości położonych liter.

Request:

```json
{
  "move_type": "place_tiles",
  "tiles": [
    { "letter": "K", "x": 7, "y": 7 },
    { "letter": "O", "x": 8, "y": 7 },
    { "letter": "T", "x": 9, "y": 7 }
  ]
}
```

Response `201 Created`: obiekt `Move`.

Reguły:

- Plansza ma zakres `x: 0..14`, `y: 0..14`.
- Nie można położyć litery poza planszą.
- Nie można położyć litery na zajętym polu.
- Gracz może użyć tylko liter, które ma na racku.
- Po ruchu rack jest uzupełniany do 7 liter, jeśli worek nie jest pusty.
- Wynik jest liczony po stronie backendu.

Błędy specyficzne:

- `422` z `"Tiles can't be blank"`.
- `422` z `"Tile is outside the board"`.
- `422` z `"Tile position is already occupied"`.
- `422` z `"Rack does not include all requested tiles"`.

Przykład:

```bash
curl -s -X POST http://localhost:3000/api/v1/games/1/moves \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"move_type":"place_tiles","tiles":[{"letter":"K","x":7,"y":7},{"letter":"O","x":8,"y":7},{"letter":"T","x":9,"y":7}]}'
```

## GET /admin

Niezabezpieczony panel HTML do lokalnego testowania i administracji MVP.

Autoryzacja: nie wymaga.

Response `200 OK`, `text/html`.

Widok zawiera:

- liczby użytkowników, gier, aktywnych gier i ruchów,
- ostatnie gry z linkami do szczegółów,
- ostatnich użytkowników wraz z tokenami,
- przykładowy słownik.

Przykład:

```bash
curl -s http://localhost:3000/admin
```

## GET /admin/games/:id

Szczegóły gry w panelu HTML.

Autoryzacja: nie wymaga.

Response `200 OK`, `text/html`.

Widok zawiera:

- status gry,
- aktualną turę,
- zwycięzcę,
- liczbę liter w worku,
- graczy wraz z rackami,
- planszę 15x15,
- historię ruchów,
- surowy stan gry w JSON.

Błędy:

- `404` gdy gra nie istnieje.

Przykład:

```bash
curl -s http://localhost:3000/admin/games/1
```
