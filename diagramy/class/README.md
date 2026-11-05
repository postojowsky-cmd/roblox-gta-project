# Diagram klas UML — Roblox City Heist: Drive & Escape

Diagram przedstawia **projektowane klasy domenowe** gry, a nie deklarację istniejących, uruchomionych skryptów Luau. Został oparty na dokumentacji ERD i diagramach aktywności oraz sekwencji.

## Pliki
- `diagram_klas_roblox_gta.dot` — edytowalny kod Graphviz.
- `diagram_klas_roblox_gta.png` — obraz diagramu (do wygenerowania z DOT).
- `zasady_diagramu_klas.pdf` — opracowanie zasad UML (osobny plik).

## Klasy
- **Player** — gotówka, konto bankowe, poziom poszukiwania.
- **Vehicle** — model, stan, kolor i tuning.
- **Inventory** — zarządzanie przedmiotami gracza.
- **Item** — ogólny przedmiot dostępny w grze.
- **Weapon** — specjalizacja Item z amunicją i obrażeniami.
- **Mission** — zadania i nagrody.
- **Robbery** — napady i cooldown.
- **Transaction** — historia operacji ekonomicznych.
- **PoliceSystem** — obsługa pościgów i poziomu poszukiwania.

## Zasady modelowania
- Znak `-` oznacza prywatny atrybut, `+` publiczną metodę.
- Puste zakończenie trójkątne oznacza dziedziczenie (`Weapon` → `Item`).
- `1` oznacza dokładnie jeden obiekt; `0..*` dowolną liczbę obiektów.
- Linie przerywane oznaczają zależność.
- Relacja Player–Mission jest logicznie wiele-do-wielu; w ERD jest odwzorowana przez `postep_misji`.
- UML przedstawia zachowanie obiektów, a ERD strukturę zapisu danych. Nazwy i typy są koncepcyjne, nie stanowią gotowego API.

## Generowanie PNG
```bash
dot -Tpng diagram_klas_roblox_gta.dot -o diagram_klas_roblox_gta.png
```
