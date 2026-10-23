# Catálogo en tiempo real con Flutter y Cloud Firestore

Proyecto de la **Semana 07 · Desarrollo Móvil Integral**: *Consumo reactivo en tiempo real con Flutter*.

## ¿Qué hace esta app?

Muestra una lista de productos (colección `items` de Cloud Firestore) que **se actualiza sola**: si creas, editas o borras un registro en Firebase Console, la pantalla cambia en menos de un segundo, **sin pull-to-refresh** y sin que el usuario haga nada.

Esto se logra con el modelo *push* (Firestore avisa de cada cambio) en lugar del modelo *pull* (la app pregunta cada vez).

La pantalla maneja cuatro estados:

| Estado | Cuándo se muestra |
|---|---|
| **Loading** | Indicador de carga mientras llega la primera respuesta. |
| **Success** | Lista de tarjetas con `ListView.builder`. |
| **Empty** | Aviso "Aún no hay registros" si la colección está vacía. |
| **Error** | Mensaje amigable (sin trazas técnicas) y botón **Reintentar**. |

## Arquitectura

```
lib/
├── main.dart                   # Inicializa Firebase y arranca la app
├── models/
│   └── item_model.dart         # Modelo: documento remoto -> objeto seguro
├── services/
│   └── catalog_service.dart    # Repositorio: consulta Firestore, ordena y limita
└── views/
    └── catalog_view.dart       # Vista: StreamBuilder + estados de la UI
```

- **Modelo (`ItemModel`)**: `ItemModel.fromFirestore(DocumentSnapshot)` convierte el documento y valida nulos (título por defecto, precio 0.0, fecha opcional). Nunca falla por un campo faltante.
- **Servicio (`CatalogService`)**: `getCatalogStream()` devuelve un `Stream<List<ItemModel>>` con `orderBy('createdAt', descending: true)` y `limit(50)`.
- **Vista (`CatalogView`)**: consume el Stream con `StreamBuilder`. Este widget se suscribe y cancela la suscripción por ti, así que no hay fugas de memoria ni suscripciones zombi.
- **`main.dart`**: llama a `WidgetsFlutterBinding.ensureInitialized()` y `Firebase.initializeApp()` antes de `runApp`. Sin `ensureInitialized`, los canales nativos fallan al arrancar.

## Configuración

### 1. Requisitos
- Flutter SDK 3.x (Dart `>=3.0.0 <4.0.0`)
- Una cuenta de Firebase y un proyecto creado en [Firebase Console](https://console.firebase.google.com)

### 2. Crear la estructura nativa (si aún no existe)
Si solo tienes la carpeta `lib/` y `pubspec.yaml`, genera las carpetas `android/` e `ios/` en la raíz del proyecto:

```bash
flutter create .
```

### 3. Conectar con Firebase
La forma más sencilla es con FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Alternativa manual en Android:
1. Registra la app en Firebase con el mismo `applicationId` que aparece en `android/app/build.gradle`.
2. Descarga `google-services.json` y colócalo en `android/app/`. **Debe coincidir exactamente con el `applicationId`.**
3. Agrega la huella digital **SHA-1** de tu llave en la configuración de la app en Firebase.

> Nota: `main.dart` usa `Firebase.initializeApp()` sin parámetros, que funciona con `google-services.json` (Android) o `GoogleService-Info.plist` (iOS). Si usas `flutterfire configure`, cambia la línea a `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.

### 4. Habilitar Firestore
En Firebase Console: **Build → Firestore Database → Crear base de datos** en **modo de prueba**.

### 5. Instalar dependencias y ejecutar
```bash
flutter pub get
flutter run
```

## Estructura de los documentos

Crea la colección `items` con documentos como este:

| Campo | Tipo | Ejemplo |
|---|---|---|
| `title` | string | `Teclado mecánico` |
| `description` | string | `Switches rojos, formato 75%` |
| `price` | number | `899.5` |
| `createdAt` | timestamp | fecha y hora de creación |

> **Importante:** la consulta ordena por `createdAt`. Los documentos que no tengan ese campo **no aparecerán** en la lista.

## Cómo probar la reactividad (Hito 4)

1. **Manipulación remota**: con la app abierta, crea, edita o borra documentos en Firebase Console. La lista debe cambiar en menos de un segundo.
2. **Sin pull-to-refresh**: comprueba que las tarjetas se agregan, reordenan y eliminan sin tocar la pantalla.
3. **Simulación offline**: activa el modo avión. La app sigue mostrando los datos desde la caché local, sin crashes. Al volver la señal se reconecta sola y sincroniza.
4. **Permisos**: revisa la consola del emulador para descartar errores de permisos de Firestore.

## Problemas comunes

- **Pantalla de error al abrir**: revisa las reglas de Firestore (modo prueba) y que `google-services.json` esté en `android/app/`.
- **La lista sale vacía**: verifica que los documentos tengan el campo `createdAt` de tipo *timestamp*.
- **Crash al arrancar**: confirma que `WidgetsFlutterBinding.ensureInitialized()` esté antes de `Firebase.initializeApp()`.
- **Firestore pide un índice**: si luego combinas `where` con `orderBy`, la consola mostrará un enlace para crearlo.

## Para reflexionar

¿En qué flujos de tu aplicación tiene sentido un `Stream` y en cuáles basta un `Future`? Un `Stream` encaja con datos que cambian mientras la app está abierta (chats, catálogos colaborativos); un `Future` basta para consultas puntuales de una sola respuesta.