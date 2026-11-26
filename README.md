# Roblox City Heist: Drive & Escape

## Aktualny stan — 26.11.2026

**Krok 120 — zakończona sesja deweloperska.** Nowy układ miasta: 198 budynków (65 centralnych), 8 parkingów, stacja paliw, góry, lasy, park i willa z przejezdnym podjazdem. W ostatnim teście wygenerowano 10 zagospodarowanych działek oraz 42 nasadzenia żywopłotu. Próba połączenia ślepych ulic nie dała rezultatów (0 połączeń, 0 placów do zawracania).

**[Dziennik sesji 26.11.2026 — wykonane prace, wyniki testów i plan kroku 121](docs/SESSION_2026-11-26.md).**

Gałąź rozwojowa: `feature/saab-ground-placement`. Główny skrypt mapy: `src/cityheist/CityReplan94.server.lua`. Ostatni test: lokalne miejsce `City Heist Drive Escape v92.rbxl`, Roblox Studio + Rojo.

**Uwaga:** najnowszy świat powstaje w Play, nie jest jeszcze trwale zapisany ani opublikowany. Do odtworzenia potrzebne są lokalne szablony i dostępne assety Creator Store. Następny krok: naprawa ślepych ulic i połączenia terenu z drogami, następnie trwały zapis świata.

---

## Aktualny stan — 23.11.2026

**Sesja zakończona.** W Roblox Studio potwierdzono wygenerowanie **28 dodatkowych budynków (20 + 8)**, **65 dekoracji** (23 drzewa, 28 latarni, 14 ławek), **2 parkingów**, **1 stacji benzynowej** oraz **3 oznaczonych dojazdów**. Saab został przetestowany przy stacji. Oryginalne drogi i istniejące mechaniki pozostały bez zmian.

**Pełny dziennik zmian, nazwy skryptów, checklistę zabezpieczenia pracy i plan kroku 90:** [docs/SESSION_2026-11-23.md](docs/SESSION_2026-11-23.md).

> **Ważne:** ta rozbudowa na razie działa w trybie testowym **Roblox Studio / Play**. Skrypty używają `RunService:IsStudio()`, a modele powstają dynamicznie. Nie oznacza to, że nowe obiekty zostaną automatycznie trwale zapisane w `.rbxl` lub pojawią się w opublikowanej grze. Przed wydaniem potrzebne jest zapisanie/bake mapy albo przygotowanie bezpiecznego trybu produkcyjnego i weryfikacja uprawnień do assetów.

**Po zakończeniu sesji:** sprawdź `git status`, pobierz najnowsze zmiany `git pull` na gałęzi `feature/saab-ground-placement`, zachowaj kopię miejsca Roblox Studio, a następną sesję zacznij od kontroli dojazdów i decyzji o trwałym zapisie mapy.

---

## Aktualny stan projektu — 16.11.2026

**Status: grywalny prototyp w Roblox Studio; dalszy rozwoj w toku.** Ponizsze funkcje zostaly zbudowane i przetestowane w lokalnym pliku `Game.rbxl`.

### Zrealizowane
- [x] **Mapa CityBlockout:** drogi, chodniki, centrum Downtown, budynki i lokacje rozgrywki.
- [x] **Trzy banki:** wnetrza, sejfy, drzwi skarbcow, napady z odliczaniem, nagrodami Money i cooldownem.
- [x] **Ekonomia:** poczatkowe 5000 Money oraz wyplaty za udane napady (leaderstats).
- [x] **Wanted i policja NPC:** poziom poszukiwan, poscig i aresztowanie gracza.
- [x] **Wiezienie CityPrison:** cele, pietra, dziedziniec, stolowka, warsztat i dojazd.
- [x] **Odsiadka:** licznik wyroku, prace skracajace czas oraz HUD.
- [x] **Ucieczka:** ukryty wlaz, tunel, krata wyjsciowa i teleport poza wiezienie.
- [x] **Straznicy NPC:** modele straznikow oraz reakcja na alarm.
- [x] **Alarm wiezienny:** migajace czerwone swiatla i sygnal do reakcji straznikow.

### Nastepne zadania
- [ ] **AI straznikow 6H-6:** polaczenie patrolu i reakcji na alarm, wykrywanie uciekiniera, stabilny poscig oraz ponowne aresztowanie.
- [ ] **Balans wiezienia:** trudniejsze prace, kara za nieudana ucieczke, testy kolizji i spawn pointow.
- [ ] **Dalsza rozgrywka:** pojazdy, tuning, kolejne napady, trwaly zapis postepow i testy multiplayer.

**Uwaga:** opis dotyczy stanu testowanego w Roblox Studio. Sam wpis w README nie aktualizuje binarnego pliku `Game.rbxl`; po kolejnych zmianach nalezy go zapisac i osobno wyslac do repozytorium.

---


> **Oficjalny projekt szkolny na zajecia zawodowe z zakresu programowania i kontroli wersji.**
> 
> *Zanurz sie w niebezpiecznym, tetniacym zyciem otwartym swiecie, gdzie liczy sie refleks, spryt i szybkie samochody. Przejmij kontrole nad ulicami miasta jako przestepca planujacy skoki zycia lub stan po stronie prawa i powstrzymaj fale przestepczosci!*

---

## O Gra i Koncepcja (Project Teaser)

**Roblox City Heist** to wieloosobowa gra akcji w otwartym swiecie stworzona w srodowisku **Roblox Studio**, inspirowana mechanikami serii *Grand Theft Auto (GTA)*.

Gracze trafiaja do tetniacej zyciem metropolii, w ktorej kazda decyzja ma swoje konsekwencje. Zorganizuj napad na lokalny bank, obrabuj kase pancerna w sklepie, a nastepnie wskakuj w podrasowane auto i uciekaj przed oblawa policji! 

### Kluczowe Funkcje Gry:
* **System Napadow i Skokow:** Interaktywne lokacje (sklepy, bankomaty, sejfy) z dynamicznym odliczaniem czasu ucieczki i czasem odnowienia (cooldown).
* **Dynamiczny Poziom Poszukiwan (Heat System):** Im wiekszy skok, tym wiecej gwiazdek poscigu! Zwiekszajacy sie poziom trudnosci i agresja policji.
* **Fizyka i Tuning Pojazdow:** Model prowadzenia aut dostosowany do dynamicznych ucieczek, poslizgow i wymijania blokad drogowych.
* **Ekonomia i Postep Gracza:** Zapisywanie gotowki, kupowanie broni, ekwipunku oraz unikalnych pojazdow (`DataStoreService`).
* **Szybka Iteracja z AI:** Wykorzystanie narzedzi sztucznej inteligencji (Roblox Assistant / AI Scripting) do szybkiego tworzenia i optymalizacji kodu w Luau.

---

## Stan Projektu i Wykonane Prace (Progress Log)

### Co zostalo zrobione do tej pory?
- [x] **Konfiguracja SSH:** Wygenerowanie i dodanie klucza SSH (`ed25519`) na koncie GitHub dla bezpiecznego polaczenia.
- [x] **Inicjalizacja Repozytorium:** Utworzenie struktury projektu, pliku `README.md` oraz `.gitignore` wykluczajacego zbedne pliki tymczasowe Robloxa (`*.lock`).
- [x] **Polaczenie z Serwerem:** Poprawne skonfigurowanie zdalnego repozytorium (`git remote`) i wykonanie pierwszego commita na galezi `main`.
- [x] **Architektura Gry:** Przygotowanie zarysu skryptow w jezyku **Luau** (system `leaderstats` i obsluga zdarzen `ProximityPrompt`).

---

## Mapa Drogowa (Roadmap & Co Dalej?)

- [ ] **Krok 1:** Zapisanie pliku gry `Game.rbxl` bezposrednio w folderze repozytorium.
- [ ] **Krok 2:** Wygenerowanie i wdrozenie skryptu napadu na sklep przy pomocy asystenta AI.
- [ ] **Krok 3:** Stworzenie systemu zapisu gotowki i poziomow poszukiwan w `DataStoreService`.
- [ ] **Krok 4:** Implementacja modeli pojazdow z systemem tuningu.
- [ ] **Krok 5:** Finalne testy gry z udzialem graczy i oddanie projektu nauczycielowi.

---

## Technologie i Narzedzia

* **Silnik gry:** Roblox Studio
* **Jezyk skryptowy:** Luau (Lua 5.1+)
* **Wsparcie programistyczne:** Roblox Assistant AI / GPT Script Gen
* **System kontroli wersji:** Git & GitHub (autoryzacja SSH)
* **Srodowisko terminala:** Git Bash / PowerShell

---

## Sciegawka dla Dewelopera (Git Workflow)

Gdy wprowadzane sa nowe zmiany w Roblox Studio, zapisujemy plik gry (`Ctrl + S`) i wklejamy w terminalu komendy:

```bash
# 1. Pobranie ewentualnych zmian z serwera
git pull

# 2. Zaznaczenie wszystkich zmodyfikowanych plikow
git add .

# 3. Zapisanie wersji z opisem zmian
git commit -m "Opis nowej funkcjonalnosci (np. dodano skrypt napadu)"

# 4. Wysylka zmian na konto GitHub
git push