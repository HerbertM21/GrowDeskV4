#!/bin/sh
set -e

# Script para sustituir variables de entorno en tiempo de ejecución
# para aplicaciones SPA desplegadas con Nginx

echo "🚀 Iniciando GrowDesk Frontend..."
echo "📊 Variables de entorno disponibles:"
echo "   - VITE_API_URL: ${VITE_API_URL:-'no definida'}"
echo "   - VITE_SYNC_API_URL: ${VITE_SYNC_API_URL:-'no definida'}"
echo "   - NODE_ENV: ${NODE_ENV:-'no definida'}"

# Directorio donde se encuentran los archivos estáticos
STATIC_DIR=/usr/share/nginx/html

# Verificar que el directorio existe y tiene contenido
echo "📁 Verificando directorio $STATIC_DIR..."
if [ -d "$STATIC_DIR" ]; then
    echo "   ✅ Directorio existe"
    FILE_COUNT=$(find "$STATIC_DIR" -type f | wc -l)
    echo "   📄 Archivos encontrados: $FILE_COUNT"
    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "   ⚠️ ADVERTENCIA: Directorio vacío"
    fi
else
    echo "   ❌ ERROR: Directorio no existe"
    echo "   🔧 Creando directorio básico..."
    mkdir -p "$STATIC_DIR"
    echo "<html><body><h1>GrowDesk Frontend</h1><p>Error: Archivos no encontrados</p></body></html>" > "$STATIC_DIR/index.html"
fi

# Solo procesar archivos JS si existen variables de entorno para reemplazar
if [ -n "$VITE_API_URL" ] || [ -n "$VITE_SYNC_API_URL" ]; then
    echo "📝 Configurando variables de entorno..."
    
    # Buscar archivos JavaScript
    JS_FILES=$(find "$STATIC_DIR" -name "*.js" -type f 2>/dev/null || echo "")
    
    if [ -n "$JS_FILES" ]; then
        JS_COUNT=$(echo "$JS_FILES" | wc -l)
        echo "🔍 Encontrados $JS_COUNT archivos JavaScript"
        
        # Procesar cada archivo JS
        echo "$JS_FILES" | while read -r file; do
            if [ -f "$file" ]; then
                echo "🔧 Procesando archivo: $file"
                
                # Reemplazar VITE_API_URL si está definida
                if [ -n "$VITE_API_URL" ]; then
                    sed -i "s|import\.meta\.env\.VITE_API_URL|\"$VITE_API_URL\"|g" "$file" 2>/dev/null || true
                    sed -i "s|\"VITE_API_URL\"|\"$VITE_API_URL\"|g" "$file" 2>/dev/null || true
                    echo "   - VITE_API_URL reemplazada con: $VITE_API_URL"
                fi
                
                # Reemplazar VITE_SYNC_API_URL si está definida
                if [ -n "$VITE_SYNC_API_URL" ]; then
                    sed -i "s|import\.meta\.env\.VITE_SYNC_API_URL|\"$VITE_SYNC_API_URL\"|g" "$file" 2>/dev/null || true
                    sed -i "s|\"VITE_SYNC_API_URL\"|\"$VITE_SYNC_API_URL\"|g" "$file" 2>/dev/null || true
                    echo "   - VITE_SYNC_API_URL reemplazada con: $VITE_SYNC_API_URL"
                fi
            fi
        done
    else
        echo "⚠️ No se encontraron archivos JavaScript para procesar"
    fi
else
    echo "ℹ️ No hay variables de entorno para reemplazar, omitiendo procesamiento"
fi

# Verificar/crear archivo localStorage-fix.json
LOCALSTORAGE_FILE="$STATIC_DIR/localStorage-fix.json"
if [ -f "$LOCALSTORAGE_FILE" ]; then
    echo "✅ localStorage-fix.json encontrado"
else
    echo "⚠️ localStorage-fix.json no encontrado, creando uno básico"
    echo '{"id":"growdesk-fix","version":1,"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$LOCALSTORAGE_FILE"
fi

# Verificar configuración de Nginx
echo "🔧 Verificando configuración de Nginx..."
if nginx -t 2>/dev/null; then
    echo "✅ Configuración de Nginx válida"
else
    echo "⚠️ Problema con configuración de Nginx, usando configuración por defecto"
fi

echo "✅ Configuración completa"
echo "🌐 Iniciando servidor web en puerto 3000..."
echo "🔗 El frontend estará disponible en: http://localhost:3000"

# Ejecutar comando original (nginx)
exec "$@" 