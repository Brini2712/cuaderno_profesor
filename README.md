# Cuaderno Profesor (Flutter + Firebase)

Aplicación móvil/web tipo Classroom para profesores y alumnos: registro de usuarios, materias, asistencias, evidencias y reportes.

## Requisitos
- Flutter SDK (3.x)
- Dart SDK (incluido con Flutter)
- Cuenta de Firebase

## Configuración rápida (desarrollo)
1. Clona el repositorio y entra al proyecto.
2. Instala dependencias:
	- `flutter pub get`
3. Configura Firebase en el proyecto:
	- Instala FlutterFire CLI (si no la tienes): `dart pub global activate flutterfire_cli`
	- Inicia sesión: `firebase login`
	- Vincula el proyecto: `flutterfire configure`
	- Esto generará `lib/firebase_options.dart` con la configuración de tu proyecto.
4. Crea la base de datos Firestore:
	- Ve a la [Consola de Firebase](https://console.firebase.google.com/).
	- Selecciona tu proyecto y entra a "Firestore Database" en el menú lateral.
	- Haz clic en "Crear base de datos" y selecciona el modo de prueba para desarrollo.
	- Confirma y espera a que se cree la base de datos.
5. Habilita la autenticación por email:
	- En la consola de Firebase, ve a "Authentication" > "Método de acceso".
	- Haz clic en "Correo electrónico/contraseña" y activa el interruptor.
	- Guarda los cambios.
6. Reglas de Firestore (solo para desarrollo):
	```
	service cloud.firestore {
	  match /databases/{database}/documents {
		 match /{document=**} {
			allow read, write: if true;
		 }
	  }
	}
	```
7. Ejecuta la app:
	- Web: `flutter run -d chrome`
	- Android: `flutter run -d android`
	- iOS/macOS/Windows según disponibilidad.

## Estructura principal
- `lib/main.dart`: Inicialización de Firebase y routing con GoRouter.
- `lib/screens/login_screen.dart`: Registro e inicio de sesión.
- `lib/providers/cuaderno_provider.dart`: Estado global (usuarios, materias, asistencias, evidencias, calificaciones).
- `lib/services/auth_service.dart`: Autenticación y perfil en Firestore.
- `lib/models/`: Modelos de datos (Usuario, Materia, Asistencia, Evidencia, Calificación).

## Notas de seguridad
- El archivo `lib/firebase_options.dart` (cliente) es seguro de commitear.
- No subas claves de servicio (admin SDK), archivos `.env` ni keystores. Ya están ignorados en `.gitignore`.
- Cambia las reglas de Firestore antes de producción para restringir acceso por usuario/rol.

## Problemas comunes
- "client is offline": verifica conexión y que Firestore esté habilitado.
- "permission-denied": ajusta las reglas de Firestore.
- Botón de login/registro se queda cargando: asegúrate de tener Firestore activo y revisa la consola de logs.

## Scripts útiles
- Actualizar paquetes: `flutter pub upgrade`
- Análisis estático: `flutter analyze`
- Formateo: `dart format .`

## Colaboración y Firebase

### Usar el mismo backend de Firebase
Todos los colaboradores pueden usar el mismo backend de Firebase (autenticación y Firestore) si tienen acceso a la configuración del proyecto. Para desarrollo, se recomienda usar reglas abiertas y nunca compartir claves privadas en público.

### Usar un proyecto de Firebase personal
Si cada colaborador quiere hacer pruebas con su propio backend de Firebase:

1. Crea un nuevo proyecto en [Firebase Console](https://console.firebase.google.com/).
2. Agrega una app (Android/iOS/Web) y descarga la configuración correspondiente (`google-services.json`, `GoogleService-Info.plist`, etc).
3. Usa el [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) para generar el archivo `lib/firebase_options.dart`:
	```sh
	flutterfire configure
	```
	Sigue los pasos y selecciona tu proyecto personal.
4. Reemplaza los archivos de configuración en tu entorno local.
5. Ajusta las reglas de Firestore/Auth para tus pruebas.

> **Nota:** El código base es el mismo para todos. Solo cambia la configuración de Firebase.

> **Tip:** Puedes cambiar de backend simplemente regenerando `firebase_options.dart` y actualizando los archivos de configuración.
# cuaderno_profesor

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
