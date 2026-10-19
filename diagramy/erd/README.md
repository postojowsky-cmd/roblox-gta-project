# ERD – Roblox City Heist: Drive & Escape

Dokumentacja logicznego modelu danych dla gry Roblox GTA.

## Diagram
Plik `erd_roblox_gta.dot` zawiera dziewięć encji: gracz, pojazd, przedmiot, ekwipunek, misja, postep_misji, napad, bron, transakcja.

## Klucze i relacje
PK oznacza klucz główny, FK oznacza klucz obcy. Relacja 1 : 0..* oznacza jeden rekord nadrzędny i zero lub wiele rekordów podrzędnych. Ekwipunek oraz postęp misji są tabelami łącznikowymi.

## Eksport
`dot -Tpng erd_roblox_gta.dot -o erd_roblox_gta.png`
`dot -Tsvg erd_roblox_gta.dot -o erd_roblox_gta.svg`

## Uwagi
Model relacyjny służy dokumentacji szkolnej. Roblox DataStoreService zapisuje dane jako klucz–wartość, nie jako tabele SQL.