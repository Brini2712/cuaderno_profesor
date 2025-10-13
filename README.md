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
4. Activa Firestore Database en la consola de Firebase.
5. Reglas de Firestore (solo para desarrollo):
	```
	service cloud.firestore {
	  match /databases/{database}/documents {
		 match /{document=**} {
			allow read, write: if true;
		 }
	  }
	}
	```
6. Ejecuta la app:
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

## Colaboradores
Para usar otro proyecto Firebase, cada colaborador puede correr `flutterfire configure` con su propio proyecto; el resto del código permanece igual.
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
