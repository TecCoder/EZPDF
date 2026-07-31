# NightPDF — plan y prompt para Codex

## 1. Objetivo

Crear una aplicación nativa para iPad que permita:

- Importar y abrir archivos PDF desde la app Archivos.
- Leerlos con navegación, zoom y desplazamiento fluidos.
- Activar un **modo nocturno real**:
  - fondo blanco → negro;
  - texto negro → blanco;
  - transformación únicamente visual, sin modificar el PDF original.
- Recordar el último documento, la última página y las preferencias de lectura.
- Funcionar completamente sin conexión y sin recopilar datos.

Nombre provisional: **NightPDF**.

---

## 2. Decisión técnica

### Plataforma y flujo de desarrollo

- Aplicación nativa para **iPadOS**.
- Desarrollo principal desde **Windows**.
- Repositorio alojado en **GitHub**.
- Codex trabaja directamente sobre el repositorio.
- Compilación y tests mediante **GitHub Actions** usando un runner `macos-*` con Xcode.
- Lenguaje: **Swift**.
- Interfaz: **SwiftUI**.
- Renderizado de PDF: **PDFKit**, mediante `PDFView`.
- Selector de archivos: `fileImporter` con `UTType.pdf`.
- Persistencia sencilla:
  - `UserDefaults` / `AppStorage` para preferencias;
  - copia del PDF al contenedor privado de la aplicación.

La aplicación debe poder generarse como un archivo `.ipa` sin firmar o preparado para firma posterior. La instalación personal desde Windows se realizará mediante AltStore Classic o Sideloadly, que firman el `.ipa` con un Apple Account gratuito para el iPad concreto.

### Por qué esta arquitectura

`PDFView` ya proporciona navegación, zoom, selección de texto e historial de páginas. SwiftUI se usará para toda la interfaz y se integrará `PDFView` mediante `UIViewRepresentable`.

El modo nocturno debe aplicarse como un filtro de representación sobre la vista, no reescribiendo el documento.

---

## 3. Alcance del MVP

### Pantalla de biblioteca

- Botón **Abrir PDF**.
- Lista de documentos importados recientemente.
- Para cada documento:
  - nombre;
  - última página;
  - fecha de última apertura;
  - botón para eliminarlo de la biblioteca.
- Al eliminar un documento de la biblioteca, no borrar el original de iCloud Drive o Archivos.

### Pantalla del lector

- PDF a pantalla completa.
- Desplazamiento vertical continuo.
- Zoom con gesto de pellizco.
- Pulsación en el centro para mostrar u ocultar controles.
- Barra superior:
  - volver;
  - título;
  - búsqueda;
  - opciones.
- Barra inferior:
  - página actual / total;
  - control para saltar de página;
  - botón de modo de visualización.

### Modos de visualización

Implementar los siguientes modos:

1. **Original**
   - PDF sin transformación.

2. **Nocturno**
   - Inversión de luminancia para obtener fondo negro y texto blanco.
   - Debe funcionar también con PDFs escaneados.
   - Es aceptable que las fotografías se vean en negativo en este primer MVP.

3. **Nocturno suave**
   - Inversión seguida de reducción de contraste o ajuste de brillo.
   - Fondo casi negro, evitando blanco puro excesivamente brillante.
   - Añadir un control de intensidad entre 0 % y 100 %.

4. **Sepia**
   - Opcional si no complica el MVP.

### Preferencias

Recordar:

- modo de visualización;
- intensidad;
- orientación de lectura;
- última página por documento;
- último documento abierto.

---

## 4. Implementación del modo nocturno

Crear una abstracción:

```swift
enum ReadingAppearance: String, Codable, CaseIterable {
    case original
    case night
    case softNight
    case sepia
}
```

El filtro debe aplicarse a `PDFView` o a su vista de documento. Probar primero una implementación basada en filtros de Core Image sobre la capa:

```swift
pdfView.layer.compositingFilter = "CIColorInvert"
```

No depender ciegamente de esa línea. Codex deberá verificar su funcionamiento real en iPadOS y encapsular la aplicación de filtros en un componente:

```swift
final class PDFNightModeRenderer {
    func apply(
        appearance: ReadingAppearance,
        intensity: Double,
        to pdfView: PDFView
    )
}
```

Requisitos:

- Al volver a `.original`, retirar completamente filtros y overlays.
- No modificar `PDFDocument`.
- Evitar que la barra de herramientas y el resto de SwiftUI queden invertidos.
- Aplicar el efecto únicamente al área renderizada del PDF.
- Reaplicar el filtro cuando `PDFView.documentView` se recree.
- Probar con:
  - PDF de texto;
  - PDF con imágenes;
  - PDF escaneado;
  - PDF con páginas de distintos tamaños.

Si `compositingFilter` resulta inestable, utilizar una alternativa respaldada por Core Image o renderizado por página. Evitar generar una copia completa del PDF invertido salvo como último recurso.

---

## 5. Modelo de datos sugerido

```swift
struct LibraryDocument: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var localFileName: String
    var originalBookmarkData: Data?
    var lastPageIndex: Int
    var lastOpenedAt: Date
}
```

Servicios:

```text
Services/
├── DocumentImportService.swift
├── DocumentLibraryStore.swift
├── ReadingProgressStore.swift
└── PDFNightModeRenderer.swift
```

Vistas:

```text
Views/
├── LibraryView.swift
├── ReaderView.swift
├── PDFKitView.swift
├── ReaderToolbar.swift
├── AppearancePanel.swift
└── DocumentRow.swift
```

Estructura del proyecto:

```text
NightPDF/
├── App/
│   └── NightPDFApp.swift
├── Models/
├── Services/
├── Views/
├── Utilities/
├── Resources/
└── Tests/
```

---

## 6. Gestión de archivos

Al importar un PDF:

1. Obtener acceso temporal mediante `startAccessingSecurityScopedResource()`.
2. Copiar el PDF al directorio `Application Support/PDFs`.
3. Usar un nombre interno basado en UUID para evitar colisiones.
4. Guardar el nombre visible original en el modelo.
5. Finalizar el acceso de seguridad.
6. Abrir siempre la copia local administrada por la app.

Ventajas:

- El PDF sigue disponible aunque el proveedor de Archivos deje de estar conectado.
- Se evita depender permanentemente de security-scoped bookmarks.
- La app puede funcionar sin conexión.

Gestionar correctamente:

- nombres repetidos;
- archivos grandes;
- PDF protegido con contraseña;
- error de copia;
- PDF corrupto;
- falta de espacio.

No enviar ningún documento a servidores externos.

---

## 7. Experiencia nocturna

Además de invertir el PDF:

- Interfaz global negra o gris muy oscuro.
- Controles que desaparecen durante la lectura.
- Opción para mantener la pantalla activa mientras el lector está abierto.
- Control de brillo interno mediante un overlay negro transparente, sin cambiar permanentemente el brillo del sistema.
- Evitar animaciones llamativas.
- Soportar orientación vertical y horizontal.
- Respetar Dynamic Type en menús y biblioteca.
- Añadir VoiceOver a los controles.

---

## 8. Criterios de aceptación del MVP

La primera versión se considera terminada cuando:

- [ ] Compila sin errores en la versión estable actual de Xcode.
- [ ] Funciona en simulador de iPad y en un iPad físico.
- [ ] Permite importar un PDF desde Archivos.
- [ ] Mantiene una biblioteca local.
- [ ] Abre PDFs de texto y escaneados.
- [ ] Permite hacer zoom y desplazarse.
- [ ] El modo nocturno convierte visualmente blanco en negro y negro en blanco.
- [ ] El PDF original no se modifica.
- [ ] El filtro solo afecta al PDF.
- [ ] Recuerda la última página de cada documento.
- [ ] Recuerda la apariencia seleccionada.
- [ ] No necesita Internet.
- [ ] No contiene analítica, anuncios ni SDK de terceros.
- [ ] Incluye pruebas unitarias de persistencia e importación.
- [ ] Incluye un README con instrucciones de instalación en iPad.

---


## 9. Integración continua con GitHub Actions

El repositorio debe incluir dos workflows.

### `ci.yml`

Se ejecuta en cada `push` y `pull_request`.

Responsabilidades:

- usar un runner macOS hospedado por GitHub;
- seleccionar una versión estable de Xcode disponible en el runner;
- resolver dependencias;
- compilar para un simulador de iPad sin firma;
- ejecutar tests unitarios;
- guardar resultados de tests cuando fallen.

Ejemplo conceptual:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  build-and-test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Show Xcode version
        run: xcodebuild -version

      - name: Build and test
        run: |
          set -o pipefail
          xcodebuild \
            -project NightPDF.xcodeproj \
            -scheme NightPDF \
            -sdk iphonesimulator \
            -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' \
            CODE_SIGNING_ALLOWED=NO \
            clean test
```

Codex debe consultar los simuladores disponibles con:

```bash
xcrun simctl list devices available
```

y adaptar el destino si el modelo del ejemplo no existe.

### `build-ipa.yml`

Se ejecuta manualmente mediante `workflow_dispatch`.

Responsabilidades:

- compilar un `archive` genérico para iOS/iPadOS;
- no introducir certificados ni contraseñas personales en el repositorio;
- intentar producir un artefacto apto para firma posterior;
- empaquetar el `.app` como `.ipa` cuando sea técnicamente válido;
- subir el resultado como artifact de GitHub Actions;
- incluir también el `.xcarchive` cuando facilite la firma posterior;
- documentar claramente si el `.ipa` está sin firmar.

Reglas de seguridad:

- nunca guardar Apple ID, contraseña, contraseña específica de aplicación, certificado `.p12` ni provisioning profile dentro del repositorio;
- no imprimir secretos en logs;
- usar GitHub Secrets únicamente si en el futuro se adopta firma con una cuenta de pago;
- el flujo gratuito recomendado firma localmente desde Windows con AltStore o Sideloadly.

### Artefactos esperados

El workflow manual debe publicar:

```text
NightPDF-build/
├── NightPDF.ipa
├── NightPDF.xcarchive.zip
├── build-info.txt
└── checksums.txt
```

`build-info.txt` debe indicar:

- commit;
- fecha;
- versión de Xcode;
- SDK;
- resultado de tests;
- estado de firma;
- instrucciones de instalación.

---

## 9. Pruebas mínimas

### Unitarias

- Guardar y recuperar biblioteca.
- Guardar y recuperar última página.
- Evitar duplicados de identificador.
- Importar dos PDFs con el mismo nombre.
- Eliminar un documento de la biblioteca.
- Persistir el modo nocturno y su intensidad.

### Manuales

- PDF de 500 páginas.
- PDF escaneado de alta resolución.
- PDF con contraseña.
- PDF almacenado en iCloud Drive.
- Cambio de orientación.
- Entrada en segundo plano y reapertura.
- Cierre forzado y recuperación.
- Activación y desactivación rápida del modo nocturno.
- Comprobación de consumo de memoria.

---

## 11. Fases para Codex

### Fase 1 — Esqueleto

- Crear el proyecto SwiftUI para iPad.
- Crear la navegación Biblioteca → Lector.
- Añadir README y estructura de carpetas.
- Confirmar compilación.

### Fase 2 — Importación y biblioteca

- Implementar `fileImporter`.
- Copiar PDFs al almacenamiento privado.
- Crear y persistir `LibraryDocument`.
- Mostrar documentos recientes.

### Fase 3 — Lector PDFKit

- Integrar `PDFView` con `UIViewRepresentable`.
- Configurar escalado automático.
- Añadir desplazamiento vertical continuo.
- Detectar cambios de página.
- Restaurar progreso.

### Fase 4 — Modo nocturno

- Implementar `ReadingAppearance`.
- Aplicar inversión solo al PDF.
- Añadir modo nocturno suave e intensidad.
- Probar memoria y rendimiento.

### Fase 5 — Controles y búsqueda

- Página actual y salto de página.
- Búsqueda de texto mediante PDFKit.
- Ocultar controles al tocar.
- Pulir orientación y accesibilidad.

### Fase 6 — Pruebas y entrega

- Añadir tests.
- Corregir warnings.
- Crear icono provisional.
- Documentar cómo firmar e instalar.
- Generar un commit final limpio.

---

# Prompt maestro para Codex

Copia desde aquí y pégalo en Codex:

```text
Quiero que construyas una aplicación nativa para iPad llamada NightPDF.

OBJETIVO
La aplicación debe importar, almacenar y leer archivos PDF. Su característica principal es un modo nocturno real que transforme visualmente el fondo blanco en negro y el texto negro en blanco, para leer por la noche. La transformación no debe modificar el PDF original ni generar una copia alterada del documento.

TECNOLOGÍA OBLIGATORIA
- Swift.
- SwiftUI para la interfaz.
- PDFKit y PDFView para mostrar los documentos.
- UIViewRepresentable para integrar PDFView.
- UniformTypeIdentifiers y UTType.pdf para importar.
- Sin dependencias externas.
- Sin backend, cuentas, analítica, publicidad ni conexión a Internet.
- Orientada principalmente a iPadOS.
- Usa la versión estable actual de Swift y Xcode disponible en el entorno.
- Mantén el deployment target tan amplio como resulte razonable, sin usar APIs beta.

ARQUITECTURA
Organiza el código por Models, Services, Views, Utilities y Tests.
No concentres toda la lógica en una sola vista.
Usa tipos pequeños, nombres claros, inyección de dependencias donde aporte valor y comentarios únicamente para decisiones no obvias.

FUNCIONALIDADES DEL MVP
1. Pantalla Biblioteca.
2. Botón para importar PDF desde Archivos.
3. Copia segura del PDF a Application Support/PDFs usando un UUID interno.
4. Lista de documentos recientes.
5. Abrir, cerrar y eliminar documentos de la biblioteca.
6. Lector con PDFView, zoom y desplazamiento vertical continuo.
7. Mostrar página actual y número total de páginas.
8. Saltar a una página.
9. Recordar la última página por documento.
10. Recordar el último documento abierto.
11. Buscar texto en el PDF.
12. Ocultar y mostrar controles tocando el centro de la pantalla.
13. Modos Original, Nocturno y Nocturno suave.
14. Control de intensidad para el modo nocturno suave.
15. Interfaz oscura y adecuada para leer por la noche.
16. Funcionamiento offline.

MODO NOCTURNO
Crea:

enum ReadingAppearance: String, Codable, CaseIterable {
    case original
    case night
    case softNight
}

Encapsula el efecto en una clase PDFNightModeRenderer.

Prueba primero una inversión visual mediante filtros de Core Image o layer.compositingFilter aplicada únicamente al contenido de PDFView, preferentemente a PDFView.documentView. No inviertas la interfaz SwiftUI.

Requisitos:
- Original retira todos los filtros y overlays.
- Night invierte los colores.
- SoftNight invierte y permite reducir brillo/contraste.
- El filtro debe mantenerse al cambiar página, orientación, documento o layout.
- No alteres PDFDocument.
- Debe funcionar en PDFs normales y escaneados.
- Es aceptable en el MVP que las fotografías aparezcan en negativo.
- Si compositingFilter no es fiable, implementa una alternativa robusta y documenta el motivo.
- Vigila el rendimiento con documentos grandes.

PERSISTENCIA
Crea un modelo LibraryDocument Codable e Identifiable con:
- id;
- displayName;
- localFileName;
- lastPageIndex;
- lastOpenedAt.

Puedes usar UserDefaults para la primera versión si el acceso está encapsulado en un store y es fácilmente sustituible. No serialices el PDF dentro de UserDefaults.

ERRORES
Muestra mensajes comprensibles para:
- PDF inválido;
- PDF protegido;
- fallo de copia;
- falta de espacio;
- archivo no disponible;
- documento eliminado.

CALIDAD
- El proyecto debe compilar realmente.
- Ejecuta los tests y corrige los errores encontrados.
- No dejes pseudocódigo, TODO críticos ni métodos vacíos.
- No ocultes errores mediante force unwrap.
- Evita fugas de acceso a security-scoped resources.
- Evita ciclos de retención.
- Usa MainActor cuando sea necesario para actualizar UI.
- Comprueba el comportamiento en multitarea y rotación de iPad.

PRUEBAS
Añade pruebas unitarias para:
- persistencia de biblioteca;
- progreso;
- importación con nombres duplicados;
- eliminación;
- persistencia de apariencia.

ENTORNO DE DESARROLLO Y GITHUB
El desarrollador trabaja desde Windows y no dispone de un Mac local.

Configura el repositorio para que:
- todo el código esté versionado en GitHub;
- GitHub Actions compile y pruebe el proyecto en un runner macOS;
- exista `.github/workflows/ci.yml` para build y tests en simulador;
- exista `.github/workflows/build-ipa.yml` ejecutable manualmente;
- el workflow manual publique como artifacts el `.xcarchive` y, cuando sea técnicamente posible, un `.ipa` preparado para firma posterior;
- se use `CODE_SIGNING_ALLOWED=NO` en builds de simulador;
- no se incluyan credenciales, certificados ni provisioning profiles en el repositorio;
- se genere `build-info.txt` indicando claramente si el paquete está firmado o sin firmar;
- se documenten los pasos para descargar el artifact desde GitHub Actions.

INSTALACIÓN DESDE WINDOWS
La instalación personal se hará sin Apple Developer Program de pago.

Prepara el proyecto y la documentación para este flujo:
1. GitHub Actions compila y genera el artifact.
2. El usuario descarga el `.ipa` o `.xcarchive` en Windows.
3. El `.ipa` se firma e instala en el iPad con AltStore Classic o Sideloadly usando un Apple Account gratuito.
4. La documentación debe explicar que la firma gratuita caduca aproximadamente cada 7 días y debe refrescarse.
5. No afirmes que basta con copiar el `.ipa` al iPad.
6. No uses TestFlight en la ruta gratuita.
7. Añade instrucciones separadas para AltStore Classic y Sideloadly.
8. Si producir un `.ipa` sin firma directamente no es viable para el tipo de proyecto generado, conserva el `.xcarchive`, documenta la limitación y crea un script reproducible para empaquetar el `.app` de dispositivo cuando corresponda.

ENTREGABLES
1. Proyecto Xcode completo.
2. README.md con:
   - requisitos;
   - arquitectura;
   - cómo compilar;
   - cómo ejecutar en simulador;
   - cómo instalarlo en un iPad físico;
   - limitaciones conocidas del filtro nocturno.
3. CHANGELOG.md.
4. Resumen final de archivos creados y decisiones técnicas.
5. Resultado de build y tests.
6. `.github/workflows/ci.yml`.
7. `.github/workflows/build-ipa.yml`.
8. `docs/INSTALL_WINDOWS_IPAD.md` con AltStore Classic y Sideloadly.
9. Artifacts reproducibles con checksums y estado de firma.

MÉTODO DE TRABAJO
Trabaja por fases pequeñas.
Después de cada fase:
- compila;
- ejecuta los tests aplicables;
- corrige errores antes de continuar;
- realiza un commit descriptivo.

Empieza inspeccionando el repositorio. Si está vacío, crea el proyecto y un AGENTS.md con las normas anteriores. No me pidas confirmación para decisiones menores: elige la opción nativa más sencilla, documenta la decisión y continúa.
```

---

## 12. Cómo compilar e instalar desde Windows

### Respuesta directa

No se puede copiar un `.ipa` cualquiera al iPad y abrirlo como si fuera un `.exe`.

iPadOS exige que la aplicación:

- esté firmada con un certificado válido;
- incluya un provisioning profile;
- autorice expresamente el dispositivo o utilice un canal de distribución permitido.

No es obligatorio pagar el Apple Developer Program para instalar una app propia en tu iPad, pero con un Apple Account gratuito la firma dura normalmente **7 días**. Después hay que volver a firmar o refrescar la aplicación.

### Flujo gratuito recomendado

```text
Windows + Codex
        ↓
Repositorio GitHub
        ↓
GitHub Actions en runner macOS
        ↓
Build y tests
        ↓
Descarga de NightPDF.ipa o xcarchive
        ↓
Firma e instalación desde Windows
con AltStore Classic o Sideloadly
        ↓
NightPDF en el iPad
```

### Opción A — AltStore Classic

Requisitos:

- Windows 10 u 11.
- iTunes e iCloud instalados según las instrucciones de AltStore.
- AltServer para Windows.
- Apple Account gratuito.
- iPad conectado al PC al menos para la instalación inicial.

Funcionamiento:

1. GitHub Actions genera el artefacto.
2. Descargas `NightPDF.ipa` en Windows.
3. Instalas AltStore Classic en el iPad mediante AltServer.
4. Desde AltStore seleccionas el `.ipa`.
5. AltStore firma la app con tu Apple Account y la instala.
6. Antes de que pasen 7 días, AltStore debe refrescar la firma, normalmente mientras el PC con AltServer está disponible en la misma red.

Limitaciones habituales de la cuenta gratuita:

- perfiles de 7 días;
- máximo aproximado de 3 aplicaciones activas instaladas por este método;
- límites de App IDs registrados;
- necesidad de refresco periódico.

### Opción B — Sideloadly

Requisitos:

- Windows.
- iTunes/iCloud o componentes de dispositivos Apple compatibles.
- Sideloadly.
- Apple Account gratuito.
- iPad conectado por USB o reconocido por el equipo.

Funcionamiento:

1. Descargas el `.ipa` generado por GitHub Actions.
2. Lo abres en Sideloadly.
3. Seleccionas el iPad.
4. Introduces el Apple Account que se utilizará para la firma.
5. Sideloadly vuelve a firmar el paquete y lo instala.
6. Repites el proceso cuando expire, normalmente cada 7 días con una cuenta gratuita.

### Qué método elegir

Para una única aplicación personal:

- **Sideloadly** suele ser el camino más directo para instalar manualmente el `.ipa`.
- **AltStore Classic** resulta más cómodo si quieres refrescar la aplicación periódicamente sin reinstalarla manualmente cada semana.

### Apple Developer Program de pago

Solo es necesario para:

- TestFlight;
- App Store;
- distribución Ad Hoc gestionada de forma estable;
- certificados y perfiles de mayor duración;
- automatización de firma y despliegue mucho más sencilla.

Con la ruta gratuita no se utiliza TestFlight.

### Restricción importante del runner de GitHub

GitHub Actions puede compilar y probar la aplicación porque ejecuta macOS y Xcode. Sin embargo, el runner no está conectado físicamente a tu iPad y no debe recibir tus credenciales personales.

Por eso se separan dos tareas:

1. **GitHub compila y comprueba el proyecto.**
2. **Windows firma e instala para tu iPad mediante AltStore o Sideloadly.**

Codex debe diseñar el workflow con esta separación explícita y no afirmar que un `.ipa` sin firmar puede instalarse directamente.

## 13. Mejoras posteriores

Una vez terminado el MVP:

- anotaciones y marcadores;
- recorte automático de márgenes;
- lectura a dos páginas en horizontal;
- sincronización opcional mediante iCloud;
- estadísticas locales de lectura;
- bloqueo de orientación;
- temporizador de sueño;
- ajuste de temperatura de color;
- exportación de anotaciones;
- modo específico que preserve mejor los colores de imágenes;
- OCR local para PDFs escaneados;
- lectura en voz alta mediante APIs del sistema.

---

## 14. Recomendación práctica

Construir primero el lector con **inversión completa**. Es el método que garantiza el resultado solicitado tanto en PDFs con texto real como en PDFs escaneados.

La inversión selectiva —fondo negro, texto blanco y fotografías normales— es considerablemente más compleja porque exige distinguir contenido, imágenes y fondos en cada página. Debe dejarse para una segunda versión.
