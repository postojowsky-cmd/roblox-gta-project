# City Heist: Drive & Escape — plan rozwoju

## Priorytet (23.11.2026)
**Najpierw ukończyć ogólne systemy i zawartość gry (grywalny MVP), później dopracowywać mechaniki, animacje, pojazdy i grafikę.** Nie zaczynać teraz prac nad zamkami aut, światłami, paliwem ani detalami HUD pojazdu.

## Potwierdzone działające podstawy
- Mapa CityBlockout i 8 garaży — istnieją, mapa wymaga rozbudowy.
- Salon i zakup Saaba 9-3 Turbo X, zapamiętywanie własności — działają.
- Saab_9_3_Turbo_X_Ready: jazda i spawn w garażu — działają.
- Garaż: WYCIĄGNIJ i SCHOWAJ — oba działają (użytkownik potwierdził).
- Stabilny kod garaży na gałęzi feature/saab-ground-placement, commit 8a130cd.
- Nie modyfikować działającej fizyki Saaba i CityGarageCentralClient V8 bez potrzeby.

## Kolejność dalszych prac
1. Uporządkować i rozbudować mapę: dzielnice, drogi, podstawowe punkty orientacyjne.
2. Ukończyć podstawową zawartość świata: budynki, banki, sklepy, miejsca interakcji.
3. Dokończyć podstawowy przebieg napadu na bank: wejście, interakcja, nagroda, cooldown.
4. Dokończyć system Wanted i podstawową reakcję policji NPC / pościg.
5. Uzupełnić ekonomię i proste zadania/sposoby zarabiania.
6. Podstawowe menu/HUD i przepływ gracza między salonem, garażem, napadem i policją.
7. Test całej pętli rozgrywki i naprawa błędów blokujących.
8. Dopiero po MVP: zamki pojazdów (L), światła (H), prędkościomierz, paliwo/tankowanie, animacje, koła, wygląd, optymalizacja, dalsze auta.

## Zasady realizacji
- Każdy etap ma mieć minimalną działającą wersję, bez perfekcjonizmu.
- Małe zmiany na GitHubie, git pull + Rojo, test w Studio, dopiero potem kolejny etap.
- Zachowywać działające funkcje, robić bezpieczne punkty powrotu.
- Nie wracać teraz do więzienia (wcześniej odłożone).
- Kolejny krok: ocena obecnego stanu mapy i banków, a następnie wybór pierwszego brakującego elementu MVP.
