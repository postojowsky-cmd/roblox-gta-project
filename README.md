# Roblox City Heist: Drive & Escape

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