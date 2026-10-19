# ERD — Roblox City Heist: Drive & Escape

## Cel
Schemat logiczny przechowywania danych do gry wieloosobowej Roblox GTA. Opisuje planowane rekordy, nie gotową relacyjną bazę danych. W Roblox Studio zapis trwałych danych może zostać zaimplementowany przez DataStoreService.

## Zasady
- **PK**: unikalny identyfikator wiersza.
- **FK**: odwołanie do PK w innej tabeli.
- **1:N**: jeden gracz może mieć wiele pojazdów, napadów i transakcji.
- **N:M**: gracze i przedmioty łączy tabela `ekwipunek`, gracze i misje — `postep_misji`.
- **Opcjonalność**: kupno pojazdu lub przedmiotu rejestruje się w `transakcja`; odpowiednie FK mogą być puste, ale dla zakupu dokładnie jedno z tych pól powinno być wypełnione.

## Encje i atrybuty
### gracz

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_gracza` | `int` | PK |
| `roblox_user_id` | `bigint` | UNIQUE |
| `nazwa` | `varchar(50)` | — |
| `gotowka` | `decimal(12,2)` | — |
| `saldo_banku` | `decimal(12,2)` | — |
| `poziom_poszukiwan` | `int` | — |

### pojazd

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_pojazdu` | `int` | PK |
| `id_gracza` | `int` | FK |
| `model` | `varchar(60)` | — |
| `kolor` | `varchar(30)` | — |
| `stan` | `int` | — |
| `tuning` | `varchar(255)` | — |

### przedmiot

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_przedmiotu` | `int` | PK |
| `nazwa` | `varchar(70)` | — |
| `kategoria` | `varchar(30)` | — |
| `cena` | `decimal(12,2)` | — |

### ekwipunek

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_pozycji` | `int` | PK |
| `id_gracza` | `int` | FK |
| `id_przedmiotu` | `int` | FK |
| `ilosc` | `int` | — |

### misja

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_misji` | `int` | PK |
| `nazwa` | `varchar(80)` | — |
| `typ` | `varchar(30)` | — |
| `nagroda` | `decimal(12,2)` | — |
| `opis` | `varchar(255)` | — |

### postep_misji

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_postepu` | `int` | PK |
| `id_gracza` | `int` | FK |
| `id_misji` | `int` | FK |
| `status` | `varchar(20)` | — |
| `data_ukonczenia` | `datetime` | NULL |

### napad

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_napadu` | `int` | PK |
| `id_gracza` | `int` | FK |
| `lokalizacja` | `varchar(80)` | — |
| `wynik` | `varchar(20)` | — |
| `lup` | `decimal(12,2)` | — |
| `czas_rozpoczecia` | `datetime` | — |

### bron

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_broni` | `int` | PK |
| `id_przedmiotu` | `int` | FK UNIQUE |
| `obrazenia` | `int` | — |
| `pojemnosc_magazynka` | `int` | — |

### transakcja

| Kolumna | Typ | Klucz |
|---|---|---|
| `id_transakcji` | `int` | PK |
| `id_gracza` | `int` | FK |
| `id_pojazdu` | `int` | FK NULL |
| `id_przedmiotu` | `int` | FK NULL |
| `typ` | `varchar(30)` | — |
| `kwota` | `decimal(12,2)` | — |
| `data_transakcji` | `datetime` | — |

## Relacje i krotności

| Encja rodzic | Encja zależna | Krotność |
|---|---|---|
| gracz | pojazd | 1 : 0..N — posiada |
| gracz | ekwipunek | 1 : 0..N — ma |
| przedmiot | ekwipunek | 1 : 0..N — występuje w |
| gracz | postep_misji | 1 : 0..N — realizuje |
| misja | postep_misji | 1 : 0..N — jest realizowana |
| gracz | napad | 1 : 0..N — wykonuje |
| przedmiot | bron | 1 : 0..N — specjalizacja |
| gracz | transakcja | 1 : 0..N — wykonuje |
| pojazd | transakcja | 1 : 0..N — dotyczy |
| przedmiot | transakcja | 1 : 0..N — dotyczy |

**Wyjątek:** dla `przedmiot` → `bron` jest to relacja 1:0..1 (unikalne `id_przedmiotu`). W `transakcja` odwołania do przedmiotu/pojazdu są opcjonalne, więc pojedyncza transakcja nie musi dotyczyć danego egzemplarza. Diagram pokazuje uproszczone oznaczenia 1:0..N; te szczegóły wyjaśnia tekst.

## Powiązanie z diagramami projektu
- `kup_pojazd` → gracz, pojazd, transakcja.
- `kup_przedmiot`, `walka_i_bron` → gracz, przedmiot, ekwipunek, bron, transakcja.
- `wykonaj_misje` → misja, postep_misji, gracz.
- `sprawdz_pieniadze` → gotowka i saldo_banku gracza.
- Napady i system pościgu → napad, poziom_poszukiwan gracza.

Nazewnictwo zgodne z przeanalizowanym repozytorium `diagramy/activity`, `diagramy/sequence` i README.
