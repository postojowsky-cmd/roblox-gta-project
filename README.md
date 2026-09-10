# ???? Roblox City Heist: Drive & Escape

> **Oficjalny projekt szkolny na zaj?cia zawodowe z zakresu programowania i kontroli wersji.**
> 
> *Zanurz si? w niebezpiecznym, t?tni?cym ?yciem otwartym ?wiecie, gdzie liczy si? refleks, spryt i szybkie samochody. Przejmij kontrol? nad ulicami miasta jako przest?pca planuj?cy skoki ?ycia lub sta里 po stronie prawa i powstrzymaj fal? przest?pczo?ci!*

---

## ?? O Gra i Koncepcja (Project Teaser)

**Roblox City Heist** to wieloosobowa gra akcji w otwartym ?wiecie stworzona w ?rodowisku **Roblox Studio**, inspirowana legendarnymi mechanikami serii *Grand Theft Auto (GTA)*.

Gracze trafiaj? do t?tni?cej ?yciem metropolii, w kt車rej ka?da decyzja ma swoje konsekwencje. Zorganizuj napad na lokalny bank, obrabuj kas? pancern? w sklepie, a nast?pnie wskakuj w podrasowane auto i uciekaj przed ob?aw? policji! 

### ?? Kluczowe Funkcje Gry:
* ?? **System Napad車w i Skok車w:** Interaktywne lokacje (sklepy, bankomaty, sejfy) z dynamicznym odliczaniem czasu ucieczki i czasem odnowienia (cooldown).
* ?? **Dynamiczny Poziom Poszukiwa里 (Heat System):** Im wi?kszy skok, tym wi?cej gwiazdek po?cigu! Zwi?kszaj?cy si? poziom trudno?ci i agresja policji.
* ??? **Fizyka i Tuning Pojazd車w:** Model prowadzenia aut dostosowany do dynamicznych ucieczek, po?lizg車w i wymijania blokad drogowych.
* ?? **Ekonomia i Post?p Gracza:** Zapisywanie got車wki, kupowanie broni, ekwipunku oraz unikalnych pojazd車w (`DataStoreService`).
* ?? **Szybka Iteracja z AI:** Wykorzystanie narz?dzi sztucznej inteligencji (Roblox Assistant / AI Scripting) do szybkiego tworzenia i optymalizacji kodu w Luau.

---

## ??? Stan Projektu i Wykonane Prace (Progress Log)

### ?? Co zosta?o zrobione do tej pory?
- [x] **Konfiguracja SSH:** Wygenerowanie i dodanie klucza SSH (`ed25519`) na koncie GitHub dla bezpiecznego po??czenia.
- [x] **Inicjalizacja Repozytorium:** Utworzenie struktury projektu, pliku `README.md` oraz `.gitignore` wykluczaj?cego zb?dne pliki tymczasowe Robloxa (`*.lock`).
- [x] **Po??czenie z Serwerem:** Poprawne skonfigurowanie zdalnego repozytorium (`git remote`) i wykonanie pierwszego commita na ga??zi `main`.
- [x] **Architektura Gry:** Przygotowanie zarysu skrypt車w w j?zyku **Luau** (system `leaderstats` i obs?uga zdarze里 `ProximityPrompt`).

---

## ??? Mapa Drogowa (Roadmap & Co Dalej?)

- [ ] **Krok 1:** Zapisanie pliku gry `Game.rbxl` bezpo?rednio w folderze repozytorium.
- [ ] **Krok 2:** Wygenerowanie i wdro?enie skryptu napadu na sklep przy pomocy asystenta AI.
- [ ] **Krok 3:** Stworzenie systemu zapisu got車wki i poziom車w poszukiwa里 w `DataStoreService`.
- [ ] **Krok 4:** Implementacja modeli pojazd車w z systemem tuningu.
- [ ] **Krok 5:** Finalne testy gry z udzia?em graczy i oddanie projektu nauczycielowi.

---

## ?? Technologie i Narz?dzia

* **Silnik gry:** Roblox Studio
* **J?zyk skryptowy:** Luau (Lua 5.1+)
* **Wsparcie programistyczne:** Roblox Assistant AI / GPT Script Gen
* **System kontroli wersji:** Git & GitHub (autoryzacja SSH)
* **?rodowisko terminala:** Git Bash / PowerShell

---

## ?? ?ci?gawka dla Dewelopera (Git Workflow)

Gdy wprowadzane s? nowe zmiany w Roblox Studio, zapisujemy plik gry (`Ctrl + S`) i wklejamy w terminalu komendy:

```bash
# 1. Pobranie ewentualnych zmian z serwera
git pull

# 2. Zaznaczenie wszystkich zmodyfikowanych plik車w
git add .

# 3. Zapisanie wersji z opisem zmian
git commit -m "Opis nowej funkcjonalnosci (np. dodano skrypt napadu)"

# 4. Wysy?ka zmian na konto GitHub
git push