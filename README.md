# K-Games 2
Native 3D Vulkan Game Engine Suite built on **Godot Engine 4.7 (Vulkan Forward+ Rendering)**.

## Features
- Native Vulkan Hardware Acceleration (Direct3D 12 / Vulkan Driver Pipelines)
- True 3D Topographic Mesh Relief & PBR Materials
- 3D Dynamic Lighting, Shadows & Particle Effects
- Free Orbit Camera & Tactical Pan Controls
- 17 Modulare 3D-Spiele: Voll spielbares interaktives 3D-Schach mit Regelprüfung & KI, Schiffe versenken, Civilization (ctp2), C&C Alarmstufe Rot 2 (ra2), Risiko, Monopoly, Mensch ärgere dich nicht, Siedler von Katan, Scotland Yard, Kniffel, Lotti Karotti, Snakes & Ladders, Space Invaders, Tetris 3D, Uno, Uno Extreme und Durak
- Schlichtes und funktionales Hauptmenü, Settings mit App-Info und übersichtliche 3D-Spielauswahl
- Mobile Touch-Emulation & optimierte Touch-Schaltflächen für Android
- Automatische Multiplattform-Builds: Standalone Windows Desktop 64-bit EXE und Android APK

## Version
Current Version: **v0.012** (Format: x.xxx)

### Changelog v0.012:
- **High-Fidelity Audio-System (Absolut kein Gepiepse)**:
  - Vollständige Umstellung auf kristallklare **16-Bit PCM Studioqualität (44.100 Hz / CD-Qualität)**.
  - Das vorherige 8-Bit Lo-Fi-System und alle künstlichen Sinus-Pieptöne wurden vollständig verbannt.
  - **Dezenter haptischer UI-Klick (`click`)**: Weicher, akustisch bedämpfter Soft-Pop ohne tonale Tonhöhe (wie edle Smartphone-/Kamera-Haptik).
  - **Edler Marimba- / Holz-Akzent (`select`)**: Warmer Rosewood-Resonanzklang mit weichem Filzschlägel-Anschlag statt Synthesizer-Pieps.
  - **Akustischer Holz-Figurenzug (`move`)**: Echter haptischer Holzkorpus-Aufsetzer ("Tock") auf samtunterlegtem Brett.
  - **Echtes Würfeln (`dice`)**: Realistische Kaskade aus 5 physikalischen Aufprall- und Taumelereignissen mit nachklingender Tischresonanz.
  - **Karten-Gleiten & Schnappen (`card`)**: Authentisches Papierreibungs-Gleiten mit anschließendem elastischem Kartenschnappen.
  - **Kanonenschuss & Wucht-Explosion (`shoot`)**: Tieffrequente Druckwelle mit Sub-Bass (35-120 Hz) und realistischem Donnergrollen.
  - **Orchestraler Sieges-Akkord (`win`)**: Strahlende F-Dur-Glockenakkord-Kaskade mit physikalischen Metallobertönen.
  - **Wasser-Plätschern (`splash` / `miss`)**: Hydrodynamischer Wassereintritt und Tropfenspritzer für Schiffe versenken.
  - **Karotten-Drehung (`twist`)**: Mechanisches Klick-Klack mit doppelter Rastung für Lotti Karotti.
  - **Sanfter Niederlage-Klang (`loss`)**: Dezenter, respektvoller D-Moll-Akustikgong.
- **Bugfixes & Stabilität**:
  - `SnakesAndLadders3D.gd`: Vererbung von `Node3D` korrigiert.
  - `Chess3D.gd`: Deklaration von `ui_layer` ergänzt.

### Changelog v0.011:
- **Navigation & Menüsteuerung**:
  - Alle Vollbild-Menüs, Einstellungen, Spielauswahl und Player-Setup schließen sich nun zuverlässig mit Zurücktaste (`KEY_BACK` auf Android) oder `ESC`.
  - Die Buttons "Alle Spiele" und "Settings" wurden aus der oberen Leiste entfernt und direkt ins Hauptmenü integriert.
  - Oben links befindet sich nur noch der übersichtliche `☰ Menü` Button.
- **Schiffe versenken (Battleship 3D)**:
  - Vollständiger Fix der Siegeserkennung: Schiffe werden garantiert kollisionsfrei platziert und das Spiel endet jetzt zuverlässig, sobald alle gegnerischen Schiffssegmente versenkt wurden.
  - Statistiken (Treffer, Fehlschüsse, Genauigkeit) und Sieg/Niederlage-Modal mit Neustartfunktion hinzugefügt.
- **Scotland Yard 3D**:
  - Vollständige London-Stadtstruktur mit Straßennetzwerk, Hyde Park, Regent's Park, St. James's Park und 4 detailreichen Themse-Brücken (Tower Bridge, Westminster Bridge, London Bridge, Waterloo Bridge).
  - Die Themse (River Thames) ist nun als kontinuierliches, organisch fließendes Wasser-Mesh via `SurfaceTool` (Cubic Splines) umgesetzt – keine störenden Einzelblöcke mehr.
  - Vollständiges U-Bahn-, Bus- und Taxi-Netzwerk mit Ticketverwaltung und Sieg/Niederlage-Bedingungen.
- **Lotti Karotti 3D**:
  - Großer 3D-Hügel mit 24 sichtbaren Trittfeldern auf 4 Ebenen.
  - 4 interaktive Falltüren auf den Feldern [4, 9, 14, 19], die sich bei Karottendrehungen dynamisch öffnen.
  - 3D-Kartenstapel mit interaktiver Zieh-Animation sowie Kartenanzeige im HUD (1, 2, 3 Schritte oder Karottendrehung).
  - 4 3D-Hasen je Spieler mit lebendiger Hüpf-Animation und Ziel-Erkennung auf der Riesenkarotte.
- **Universelle 3D-Würfel**:
  - Zentrales `DiceHelper`-Modul für physikalische 3D-Würfel mit echten 6-Augen-Texturflächen und Würfel-Roll-Animationen.
  - Integriert in Mensch ärgere Dich nicht, Monopoly, Kniffel, Siedler von Katan, Risiko und Snakes & Ladders.
- **Mensch ärgere Dich nicht 3D**:
  - Authentisches 22x22 Kreuz-Spielfeld mit 40 Rundkurs-Feldern, 4 Eckhäusern und je 4 Zielfeldern.
  - 3D-Würfelwurf mit 6er-Regel, Rausschlagen und vollständigen KI-Zügen.
- **Monopoly 3D & Siedler von Katan 3D**:
  - Enorm vergrößerte Spielfelder mit originalgetreuen Proportionen, 2-Würfel-System mit Pasch-Regel, Straßen-, Haus- und Hotelbau.
- **Kniffel 3D**:
  - 5 physikalische 3D-Würfel mit Halten-/Freigeben-Funktion und originalem 13-Kategorien-Wertungsblock.
- **Echtzeit- & Action-Spiele (Tetris, Space Invaders, Alarmstufe Rot 2)**:
  - Vollwertige Gameplay-Loops statt Standbilder: Tetris mit Schwerkraft & Reihenauflösung, Space Invaders mit marschierenden Aliens, Geschossen & Bunkern, RA2 mit Panzern, Mündungsfeuer, Projektilen und animierten Tesla-Spulen.
- **Regel- und Siegprüfungen**:
  - Alle 17 Spiele wurden auf korrekte Spielregeln, Sieg- und Niederlage-Bedingungen und Responsive Touch/Maus-Steuerung überprüft.
