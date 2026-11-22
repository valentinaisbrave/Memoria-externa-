# MEMORIA EXTERNA

*Un archivo colectivo de memorias individuales.*

Aplicación web con un único escritorio 2D compartido, estética de explorador de archivos retro, memorias arrastrables, ventanas superpuestas, buscador y filtros. Desarrollada con Python/Streamlit + HTML/CSS/JavaScript sin React ni Three.js, y Supabase para autenticación, PostgreSQL, Storage y Realtime.

## Estructura

```text
memoria_externa/
├── app.py                    # Punto de entrada Streamlit (Python)
├── component/index.html      # Escritorio, ventanas, Auth y operaciones en JS
├── supabase/schema.sql       # Tablas, políticas RLS, Storage y Realtime
├── requirements.txt
├── .streamlit.example.toml   # Ejemplo de credenciales
├── .gitignore
└── README.md
```

## 1. Crear Supabase

1. Regístrate en [supabase.com](https://supabase.com), crea un proyecto y espera a que esté listo.
2. Abre **SQL Editor**, pega el contenido de `supabase/schema.sql` y ejecútalo. Esto crea `profiles`, `memories`, `desktop_settings`, un bucket público `memorias` y políticas de seguridad.
3. En **Authentication → Providers → Email**, habilita Email. Decide si deseas requerir confirmación por correo (recomendado). Configura **Authentication → URL Configuration** con la URL pública de la app para la recuperación de contraseña.
4. En **Project Settings → API Keys** (o **Connect** según el panel) copia la **Project URL** y la clave **publishable/anon**. **Nunca copies `service_role` ni `secret key` al cliente.**
5. Para un entorno abierto al público, configura límites de Auth, moderación de contenidos, protección contra spam y cuotas; revisa los límites del plan de Supabase.

## 2. Ejecutar en tu computador

1. Instala Python 3.10 o superior.
2. Abre la terminal dentro de `memoria_externa`.
3. (Opcional) `python -m venv .venv` y activa el entorno.
4. Ejecuta `pip install -r requirements.txt`.
5. Crea la carpeta `.streamlit` y el archivo `.streamlit/secrets.toml` copiando `.streamlit.example.toml`, y reemplaza URL y clave con tus valores reales.
6. Ejecuta `streamlit run app.py`. Abre la dirección que aparezca en la terminal, normalmente `http://localhost:8501`.

**Modo demostración:** sin credenciales, puedes explorar el escritorio y agregar memorias de prueba guardadas en `localStorage` del mismo navegador. **Esto NO es un archivo colectivo, ni persiste entre personas o dispositivos.** No uses el modo demo para datos importantes. Las imágenes de ejemplo ilustrativas requieren internet.

## 3. Subir el código a GitHub

1. Crea un repositorio nuevo en [github.com](https://github.com).
2. Desde esta carpeta, ejecuta:

```bash
git init
git add .
git commit -m "Primera versión MEMORIA EXTERNA"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/memoria-externa.git
git push -u origin main
```

3. Confirma que `.streamlit/secrets.toml` **no está en el repositorio** (lo excluye `.gitignore`).

## 4. Publicar con Streamlit Community Cloud

1. Entra en [share.streamlit.io](https://share.streamlit.io), inicia sesión con GitHub y crea una app.
2. Selecciona tu repositorio, rama `main` y archivo de entrada `app.py`.
3. En **Advanced settings / Secrets** pega:

```toml
SUPABASE_URL = "https://TU-PROYECTO.supabase.co"
SUPABASE_ANON_KEY = "TU_CLAVE_PUBLICA"
```

4. Despliega la app y abre su URL pública. Prueba con dos navegadores o equipos distintos.

## 5. Pruebas de aceptación

- Abre la app en dos navegadores: ambos deben ver la misma colección de memorias.
- Registra usuarios diferentes. El usuario A agrega un poema; B lo ve sin actualizar manualmente (Supabase Realtime, con refresco complementario cada 30 s).
- A arrastra su archivo; el cambio se guarda al soltarlo y reaparece tras actualizar.
- B no puede arrastrar ni eliminar los archivos de A (permisos RLS).
- Sube JPG/PNG/WEBP, PDF/TXT/DOCX (máximo 10 MB); abre imágenes, textos y PDFs, y descarga DOCX.
- A cierra sesión, entra de nuevo y conserva sus archivos.

## Notas y límites

- **Sin credenciales no se puede verificar la sincronización real.** El código y SQL están preparados, pero debes configurar y probar un proyecto real de Supabase.
- El escritorio muestra hasta 1500 registros por consulta. Para archivos masivos, implementar carga espacial paginada por rango visible y miniaturas pre-generadas.
- La política establece que **solo el propietario puede mover sus memorias**, respetando las reglas de autoría. No permite mover archivos de terceros, aunque todos sean visibles.
- Arrastres simultáneos del **mismo archivo** por usuarios distintos están bloqueados por la autorización de propietario. Dos sesiones de la **misma cuenta** pueden producir una última escritura ganadora; para un uso exigente, implementar bloqueo optimista por `updated_at`.
- Todos los archivos del bucket son públicos: antes de subir, asegúrate de que son aptos para un archivo público. Añade política de privacidad, denuncia de contenido y moderación antes de una convocatoria abierta.
- La recuperación de contraseña por email está implementada; el flujo de definición de nueva contraseña depende de configurar correctamente las URL de redirección y añadir pantalla `updateUser` tras la redirección en una versión posterior.
- La interfaz requiere conexión al CDN de la librería oficial `supabase-js` para la modalidad conectada. Para despliegue más robusto, distribuye una copia local fijada de la librería.
- **Validación funcional real pendiente** hasta disponer de una instancia Supabase y dos sesiones de prueba.
