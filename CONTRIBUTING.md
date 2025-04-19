# Guía de Contribución

¡Gracias por tu interés en contribuir a este proyecto! Aquí hay algunas pautas para ayudarte a empezar.

## Proceso de Contribución

1. Haz un fork del repositorio
2. Crea una rama para tu característica (`git checkout -b feature/amazing-feature`)
3. Realiza tus cambios
4. Asegúrate de que el script pase las pruebas de shellcheck
5. Haz commit de tus cambios (`git commit -m 'Añadir una característica increíble'`)
6. Haz push a la rama (`git push origin feature/amazing-feature`)
7. Abre un Pull Request

## Estándares de Código

- Sigue las [pautas de estilo de Google para shell scripts](https://google.github.io/styleguide/shellguide.html)
- Utiliza [shellcheck](https://www.shellcheck.net/) para verificar tu código
- Añade comentarios explicativos para funcionalidades complejas
- Mantén la compatibilidad con bash y sh cuando sea posible

## Pruebas

- Asegúrate de probar tus cambios en diferentes entornos
- Verifica que los scripts funcionen con diferentes versiones de PostgreSQL
- Prueba con diferentes configuraciones de variables de entorno

## Documentación

- Actualiza el README.md si añades o cambias funcionalidades
- Documenta todas las nuevas opciones o variables de entorno
- Proporciona ejemplos de uso para nuevas características

## Reporte de Problemas

- Utiliza el sistema de issues de GitHub para reportar problemas
- Incluye pasos detallados para reproducir el problema
- Menciona tu entorno (sistema operativo, versión de bash, versión de PostgreSQL)

¡Gracias por contribuir!
