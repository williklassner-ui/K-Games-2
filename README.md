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
Current Version: **v0.013** (Format: x.xxx)

### Changelog v0.013:
- **Schiffe versenken 3D (Authentische Kriegsschiffe & Versenkt-Anzeige)**:
  - Vollständiges militärisches Schiffsdesign mit PBR-Marinegrau, Wasserlinien-Rot und Decksbeplankung.
  - Spezifische Schiffsklassen mit individueller Bewaffnung:
    - **Flugzeugträger (5 Felder)**: Großes Flugdeck, Centerline-Startbahn, Inselbrücke, Radarmast und geparkte Marine-Jets.
    - **Schlachtschiff (4 Felder)**: 3 schwere Dreifachtürme in Superfiring-Aufstellung, Pagoden-Kommandoturm und Zwillingstürme.
    - **Schwerer Kreuzer (3 Felder)**: 2 Doppeltürme, schlanke Rumpfsilhouette und Schornstein.
    - **U-Boot (3 Felder)**: Zylindrischer Druckkörper, Turm mit Periskop und Deckgeschütz.
    - **Schnellboot (2 Felder)**: Keilrumpf mit Schnellfeuergeschütz und weißem Radom.
  - **Versenkte Schiffe auf dem Spielfeld anzeigen**: Sobald ein feindliches Schiff komplett getroffen wurde, erscheint das detaillierte 3D-Kriegsschiff-Wrack direkt auf den besetzten Spielfeldfeldern im Wasser, inklusive Krängung, brennendem Feuer, aufsteigendem Rauch und 3D-Schriftzug ("🔥 VERSENKT: [Name]").
- **Command & Conquer: Alarmstufe Rot 2 (1:1 Nachbau & Details)**:
  - Authentische Red Alert 2 Gebäude mit feinen Details und Texturen:
    - **Sowjetischer Bauhof**: Achteckige Betonplattform, rote Panzerkuppel mit erhabenem Sowjetstern und 2 gelbe Riesenkräne.
    - **Tesla-Reaktor**: Doppelte Kühltürme mit Warnringen und pulsierendem Plasmakern.
    - **Sowjetische Kaserne**: Betonbunker mit Panzertor und wehender roter Sowjet-Fahne.
    - **Waffenfabrik**: Große Montagehalle mit Chevron-Warnstreifentor und Schornsteinen.
    - **Tesla-Spule**: Pyramidaler Metallsockel, 4 gestapelte Kupfer-Induktionstori und pulsierende 10.000V-Kugel mit elektrischen Entladungsblitzen.
    - **Erz-Raffinerie**: Doppelsilos und geneigte Entladerampe.
  - **Kirov-Luftschiff**: Legendärer Kirov-Zeppelin mit Haifischmaul-Nose-Art schwebt als ständige Bedrohung über dem Schlachtfeld.
  - **Rhino-Schwerpanzer & War-Miner**: Detaillierte Kettenlaufwerke, 120mm Kanone mit Mündungsbremse und Heckfässer; automatischer Erntezyklus des Sammlers mit rotierendem Schneckenbohrer, Golderz-Abbau und +$500 Credits beim Abladen.
  - **C&C EVA Sidebar HUD**: Digitaler Credits-Zähler ($), Bau-Menü für Rhino-Panzer ($900), Tesla-Schlag ($1200) und Angriffsbefehle.
- **Lotti Karotti 3D (Runder Bergpfad, echte Löcher & 3D-Kartenziehen)**:
  - **Sichtbarer Bergpfad**: Der Weg windet sich nun als durchgehende, sichtbare Stein- und Erdstraße um den grünen Hügel; die 24 Felder haben weiten Abstand und überlagern sich an keiner Stelle.
  - **Echte Schacht-Löcher**: Die Fallenfelder besitzen nun einen echten, tiefen dunklen Schacht mit Ringkragen. Bei Karottendrehungen klappt die Falltür 90° nach unten weg, und ein getroffener Hase stürzt sichtbar tief in das Loch hinab.
  - **Runde organische Karotte**: Völlig runde, bauchige Karottenform mit Querringen, samtigem Orange-Glanz und 6 geschwungenen grünen Blättern.
  - **3D-Kartenstapel mit Ziehanimation**: Interaktiver 3D-Kartenstapel und Ablagefach auf Holztisch; beim Ziehen hebt sich die 3D-Karte in die Luft, rotiert 180° zur Kamera und zeigt die offiziellen Lotti-Karotti-Symbole (1, 2, 3 Schritte oder Karottendrehung).

### Changelog v0.012:
- **High-Fidelity Audio-System (Absolut kein Gepiepse)**:
  - Vollständige Umstellung auf kristallklare **16-Bit PCM Studioqualität (44.100 Hz / CD-Qualität)**.
  - Weicher haptischer UI-Klick (`click`), Marimba-Holzakzent (`select`), schwerer Holzaufsetzer (`move`), physikalisches Würfeln (`dice`), Kartenschnappen (`card`), wuchtige Explosion (`shoot`), F-Dur Glockenkaskade (`win`), Wasserplätschern (`splash`) und mechanische Karotten-Drehung (`twist`).
