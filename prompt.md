Zbuduj profesjonalne, czytelne i dobrze zorganizowane API w Ruby on Rails dla aplikacji typu Literaki / Scrabble.

Na tym etapie implementujemy wyłącznie backend API w Rails, bez frontendu.

Wymagania ogólne:
- Aplikacja Rails API-only.
- Ruby on Rails + PostgreSQL.
- API w formacie JSON.
- Wersjonowanie endpointów przez /api/v1.
- Kod ma być profesjonalny, czytelny, dobrze podzielony na warstwy.
- Kontrolery mają być cienkie.
- Logika biznesowa gry ma być w serwisach.
- Należy dodać testy RSpec dla modeli, requestów i najważniejszych serwisów.
- Należy używać czytelnych nazw klas, metod i zmiennych.
- Nie upychaj logiki gry w kontrolerach.
- Unikaj overengineeringu, ale przygotuj strukturę pod dalszy rozwój.

Najważniejsze założenie dotyczące użytkowników:
- Nie ma klasycznego logowania przez email i hasło.
- Użytkownik podaje wyłącznie username.
- Username jest tylko nazwą wyświetlaną.
- Po podaniu username API tworzy albo znajduje użytkownika i zwraca token.
- Od tego momentu klient posługuje się tokenem.
- Token służy do identyfikacji użytkownika przy kolejnych requestach.
- Nie implementuj emaila, hasła, resetowania hasła ani potwierdzania konta.
- Token może być prostym bezpiecznym tokenem zapisanym w bazie, np. api_token.
- Token powinien być generowany po stronie backendu.
- Token powinien być unikalny i trudny do odgadnięcia.
- Autoryzacja requestów ma działać przez nagłówek:
  Authorization: Bearer <token>

Model User:
- username:string
- api_token:string
- games_played:integer, default: 0
- games_won:integer, default: 0
- total_score:integer, default: 0

Walidacje User:
- username wymagany.
- username ma być nazwą wyświetlaną.
- api_token wymagany i unikalny.
- username nie musi być unikalny, chyba że architektura wymaga inaczej. Preferowane: username NIE jest unikalny, bo identyfikatorem technicznym jest token/id użytkownika.

Endpoint autoryzacji:
POST /api/v1/auth

Request:
{
  "username": "marek"
}

Działanie:
- Jeśli można znaleźć istniejącego użytkownika po tokenie, to późniejsze requesty identyfikują go tokenem.
- Dla POST /auth, jeśli username jest poprawny, utwórz nowego użytkownika i wygeneruj token.
- Nie próbuj logować użytkownika po username, ponieważ username nie jest tożsamością ani credentialem.
- Każde wywołanie POST /auth z username może utworzyć nowego użytkownika z nowym tokenem.
- Zwróć user oraz token.

Response:
{
  "user": {
    "id": 1,
    "username": "marek"
  },
  "token": "generated_secure_token"
}

Endpoint aktualnego użytkownika:
GET /api/v1/me

Wymaga:
Authorization: Bearer <token>

Response:
{
  "id": 1,
  "username": "marek",
  "games_played": 0,
  "games_won": 0,
  "total_score": 0
}

Modele domenowe:

Game:
- status:string
- current_turn_user_id:integer
- winner_id:integer
- board:jsonb, default: {}
- bag:jsonb, default: []
- started_at:datetime
- finished_at:datetime

Statusy gry:
- waiting
- active
- finished
- cancelled

Relacje:
- Game has_many :game_players
- Game has_many :users, through: :game_players
- Game has_many :moves
- Game belongs_to :current_turn_user, class_name: "User", optional: true
- Game belongs_to :winner, class_name: "User", optional: true

GamePlayer:
- game_id:integer
- user_id:integer
- score:integer, default: 0
- rack:jsonb, default: []
- position:integer
- passed_turns_count:integer, default: 0

Relacje:
- GamePlayer belongs_to :game
- GamePlayer belongs_to :user

Move:
- game_id:integer
- user_id:integer
- move_type:string
- tiles:jsonb, default: []
- words:jsonb, default: []
- score:integer, default: 0

Move types:
- place_tiles
- exchange_tiles
- pass
- resign

Relacje:
- Move belongs_to :game
- Move belongs_to :user

Word:
- value:string
- language:string, default: "pl"

Indeksy:
- users.api_token unique
- game_players game_id + user_id unique
- words value + language unique
- moves game_id
- moves user_id
- games status

Endpointy API:

POST /api/v1/auth
GET /api/v1/me

GET /api/v1/games
POST /api/v1/games
GET /api/v1/games/:id
POST /api/v1/games/:id/start

GET /api/v1/games/:game_id/moves
POST /api/v1/games/:game_id/moves

POST /api/v1/games:
Request:
{
  "opponent_username": "ania"
}

Działanie:
- Tworzy nową grę w statusie waiting.
- Dodaje aktualnego użytkownika jako pierwszego gracza.
- Jeżeli podano opponent_username, utwórz drugiego użytkownika jako placeholder albo zostaw to jako opcjonalne pole zależnie od prostoty implementacji.
- Preferowane na MVP: gra tworzona jest tylko z aktualnym użytkownikiem, a drugi gracz może dołączyć osobnym endpointem.

Dodaj endpoint:
POST /api/v1/games/:id/join

Działanie:
- Aktualny użytkownik dołącza do gry waiting.
- Gra może mieć maksymalnie 2 graczy.
- Nie można dołączyć dwa razy do tej samej gry.
- Nie można dołączyć do gry active lub finished.

POST /api/v1/games/:id/start:
Działanie:
- Gra musi mieć 2 graczy.
- Status musi być waiting.
- Wygeneruj worek liter.
- Rozdaj każdemu graczowi po 7 liter.
- Ustaw pustą planszę.
- Ustaw pierwszego gracza.
- Zmień status na active.
- Ustaw started_at.

GET /api/v1/games/:id:
Response ma zawierać:
- id
- status
- board
- players
- current_turn_user_id
- winner_id
- started_at
- finished_at
- moves

Ważne:
- rack liter zwracaj tylko dla aktualnie zalogowanego użytkownika.
- Dla przeciwnika nie zwracaj racka.

POST /api/v1/games/:game_id/moves:

Obsługiwane typy ruchów:

1. pass
Request:
{
  "move_type": "pass"
}

2. resign
Request:
{
  "move_type": "resign"
}

3. exchange_tiles
Request:
{
  "move_type": "exchange_tiles",
  "tiles": ["A", "E", "R"]
}

4. place_tiles
Request:
{
  "move_type": "place_tiles",
  "tiles": [
    { "letter": "K", "x": 7, "y": 7 },
    { "letter": "O", "x": 8, "y": 7 },
    { "letter": "T", "x": 9, "y": 7 }
  ]
}

Minimalne zasady dla MVP:
- Plansza 15x15.
- Gracz ma rack 7 liter.
- Gra jest dla 2 graczy.
- Ruch może wykonać tylko aktualny gracz.
- Nie można wykonać ruchu w grze, która nie jest active.
- Nie można położyć litery poza planszą.
- Nie można położyć litery na zajętym polu.
- Gracz może użyć tylko liter, które ma na racku.
- Po ruchu uzupełnij rack z worka do 7 liter, jeśli worek nie jest pusty.
- Po ruchu zmień turę na drugiego gracza.
- Zapisz ruch w historii.
- Dla place_tiles na MVP wystarczy uproszczone liczenie punktów jako suma wartości położonych liter.
- Walidację słownika można przygotować jako osobny serwis, ale w MVP może być opcjonalna albo bardzo prosta.

Serwisy do utworzenia:

Authentication:
- Auth::CreateSessionService

Games:
- Games::CreateService
- Games::JoinService
- Games::StartService
- Games::SerializeService albo serializer

Moves:
- Moves::CreateService
- Moves::PassService
- Moves::ResignService
- Moves::ExchangeTilesService
- Moves::PlaceTilesService
- Moves::ValidateTurnService
- Moves::ApplyMoveService
- Moves::ScoreService

Tiles:
- Tiles::BagService
- Tiles::RackService

Turns:
- Turns::NextPlayerService

Words:
- Words::ValidateService

Wartości liter:
Umieść konfigurację punktów liter w osobnym miejscu, np. config/initializers/tiles.rb albo app/lib/literaki/tiles.rb.

Na MVP możesz użyć uproszczonego zestawu:
A, E, I, N, O, R, S, W, Z = 1
C, D, K, L, M, P, T, Y = 2
B, G, H, J, Ł, U = 3
Ą, Ę, F, Ó, Ś, Ż = 5
Ć = 6
Ń = 7
Ź = 9

Worek liter:
Zaimplementuj jako tablicę liter w Game.bag.
Na start może być uproszczony, ale powinien działać deterministycznie i czytelnie.
Tiles::BagService powinien odpowiadać za:
- wygenerowanie worka,
- potasowanie,
- dobranie N liter,
- zwrócenie zaktualizowanego worka.

Autoryzacja:
Stwórz ApplicationController z metodami:
- authenticate_user!
- current_user

Mechanizm:
- Odczytaj nagłówek Authorization.
- Pobierz token po prefixie Bearer.
- Znajdź User po api_token.
- Jeśli brak tokenu albo użytkownika, zwróć 401 JSON:
{
  "error": "Unauthorized"
}

Obsługa błędów:
- 401 dla braku autoryzacji.
- 403 dla braku dostępu do gry.
- 404 dla nieistniejących zasobów.
- 422 dla błędów walidacji lub niepoprawnego ruchu.
- Błędy powinny być zwracane jako JSON:
{
  "errors": ["message 1", "message 2"]
}

Serializacja:
Możesz użyć Blueprinter, ActiveModelSerializers albo prostych serializerów PORO.
Ważne, żeby response były spójne i czytelne.

Transakcje:
- Start gry powinien działać w transakcji.
- Tworzenie ruchu powinno działać w transakcji.
- Aktualizacja planszy, racka, worka, wyniku i tury musi być atomowa.

Testy:
Dodaj RSpec.
Przetestuj co najmniej:

Auth:
- POST /auth tworzy użytkownika.
- POST /auth zwraca token.
- GET /me działa z poprawnym tokenem.
- GET /me zwraca 401 bez tokenu.

Games:
- zalogowany użytkownik może utworzyć grę.
- użytkownik może dołączyć do gry waiting.
- nie można dołączyć do gry active.
- nie można przekroczyć 2 graczy.
- start gry wymaga 2 graczy.
- start gry rozdaje litery i ustawia status active.

Moves:
- nieautoryzowany request zwraca 401.
- ruch może wykonać tylko gracz, którego jest tura.
- pass tworzy ruch i zmienia turę.
- resign kończy grę i ustawia winnera.
- exchange_tiles wymienia litery.
- place_tiles aktualizuje planszę, wynik, rack i turę.
- nie można użyć litery spoza racka.
- nie można położyć litery na zajętym polu.
- nie można położyć litery poza planszą.

Struktura katalogów:
app/services/auth/create_session_service.rb
app/services/games/create_service.rb
app/services/games/join_service.rb
app/services/games/start_service.rb
app/services/moves/create_service.rb
app/services/moves/pass_service.rb
app/services/moves/resign_service.rb
app/services/moves/exchange_tiles_service.rb
app/services/moves/place_tiles_service.rb
app/services/tiles/bag_service.rb
app/services/turns/next_player_service.rb
app/services/words/validate_service.rb
app/serializers/...
app/lib/literaki/...

Wymagania jakościowe:
- Stosuj service objects.
- Stosuj małe metody.
- Dodaj komentarze tylko tam, gdzie pomagają zrozumieć reguły gry.
- Nie komentuj oczywistego kodu.
- Unikaj duplikacji.
- Używaj guard clauses.
- Stosuj transakcje dla operacji modyfikujących wiele rekordów.
- Nie zwracaj racka przeciwnika.
- Nie ufaj danym z klienta przy punktacji ani turze.
- Nie pozwalaj klientowi przesyłać score, current_turn_user_id ani winner_id jako źródła prawdy.

Dostarcz:
1. Pełną implementację Rails API.
2. Migracje.
3. Modele.
4. Kontrolery.
5. Serwisy.
6. Serializery.
7. Routing.
8. Testy RSpec.
9. Seed dla przykładowych słów.
10. README z instrukcją uruchomienia, migracji, testów i przykładowymi requestami curl.

README powinien zawierać przykłady:
- utworzenie użytkownika przez username,
- użycie tokena,
- utworzenie gry,
- dołączenie do gry,
- start gry,
- wykonanie pass,
- wykonanie place_tiles,
- pobranie stanu gry.

Zadbaj o to, żeby projekt po wygenerowaniu był możliwy do uruchomienia komendami:
bundle install
rails db:create db:migrate db:seed
bundle exec rspec
rails s
