#!/bin/bash

echo "🔧 Script de diagnóstico y reparación de problemas Docker"
echo "========================================================="

# Función para limpiar contenedores y volúmenes
cleanup_docker() {
    echo "🧹 Limpiando contenedores y volúmenes..."
    docker-compose down -v --remove-orphans 2>/dev/null || true
    docker system prune -f
    docker volume prune -f
    echo "✅ Limpieza completada"
}

# Función para verificar conectividad de red
check_network() {
    echo "🌐 Verificando conectividad de red..."
    if ping -c 1 registry.npmjs.org > /dev/null 2>&1; then
        echo "✅ Conectividad con registry.npmjs.org: OK"
    else
        echo "❌ Sin conectividad con registry.npmjs.org"
        echo "💡 Sugerencia: Verificar configuración de proxy/firewall"
    fi
    
    if ping -c 1 docker.io > /dev/null 2>&1; then
        echo "✅ Conectividad con docker.io: OK"
    else
        echo "❌ Sin conectividad con docker.io"
        echo "💡 Sugerencia: Verificar configuración de Docker registry"
    fi
}

# Función para verificar Docker y Docker Compose
check_docker() {
    echo "🐳 Verificando Docker..."
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker no está instalado"
        exit 1
    fi
    
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker no está ejecutándose"
        echo "💡 Sugerencia: sudo systemctl start docker"
        exit 1
    fi
    
    echo "✅ Docker está funcionando"
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose no está instalado"
        exit 1
    fi
    
    echo "✅ Docker Compose está disponible"
}

# Función para reparar problemas específicos del entrypoint
fix_entrypoint_issues() {
    echo "🔧 Reparando problemas específicos del docker-entrypoint.sh..."
    
    ENTRYPOINT_FILE="GrowDesk/frontend/docker-entrypoint.sh"
    
    if [ -f "$ENTRYPOINT_FILE" ]; then
        echo "📁 Archivo encontrado: $ENTRYPOINT_FILE"
        
        # Verificar y corregir permisos
        if [ ! -x "$ENTRYPOINT_FILE" ]; then
            echo "🔧 Corrigiendo permisos de ejecución..."
            chmod +x "$ENTRYPOINT_FILE"
        fi
        
        # Verificar shebang
        FIRST_LINE=$(head -1 "$ENTRYPOINT_FILE")
        if [[ "$FIRST_LINE" != "#!/bin/sh" ]] && [[ "$FIRST_LINE" != "#!/bin/bash" ]]; then
            echo "⚠️ Shebang incorrecto: $FIRST_LINE"
            echo "🔧 Corrigiendo shebang..."
            sed -i '1s|^.*|#!/bin/sh|' "$ENTRYPOINT_FILE"
        fi
        
        # Verificar terminaciones de línea
        if file "$ENTRYPOINT_FILE" | grep -q "CRLF"; then
            echo "🔧 Corrigiendo terminaciones de línea CRLF..."
            if command -v dos2unix &> /dev/null; then
                dos2unix "$ENTRYPOINT_FILE"
            else
                sed -i 's/\r$//' "$ENTRYPOINT_FILE"
            fi
        fi
        
        # Verificar que el archivo no esté vacío
        if [ ! -s "$ENTRYPOINT_FILE" ]; then
            echo "❌ El archivo está vacío"
            return 1
        fi
        
        echo "✅ docker-entrypoint.sh verificado y corregido"
        echo "📋 Información del archivo:"
        ls -la "$ENTRYPOINT_FILE"
        echo "📄 Primeras líneas:"
        head -3 "$ENTRYPOINT_FILE"
        
    else
        echo "❌ docker-entrypoint.sh no encontrado en $ENTRYPOINT_FILE"
        return 1
    fi
}

# Función para construir con diagnóstico específico
build_with_diagnostics() {
    echo "🔨 Construyendo contenedores con diagnóstico..."
    
    # Reparar problemas del entrypoint antes de construir
    fix_entrypoint_issues
    
    # Construir frontend con logs detallados
    echo "📦 Construyendo growdesk-frontend..."
    if docker-compose build --no-cache --progress=plain frontend 2>&1 | tee /tmp/frontend-build.log; then
        echo "✅ growdesk-frontend construido exitosamente"
    else
        echo "❌ Error construyendo growdesk-frontend"
        echo "📋 Últimas líneas del log de construcción:"
        tail -20 /tmp/frontend-build.log
        
        # Intentar diagnóstico específico del entrypoint
        echo "🔍 Verificando si el problema es del entrypoint..."
        if grep -q "docker-entrypoint.sh" /tmp/frontend-build.log; then
            echo "🚨 Problema confirmado con docker-entrypoint.sh"
            echo "🔧 Intentando solución alternativa..."
            
            # Crear un Dockerfile temporal sin entrypoint personalizado
            cat > GrowDesk/frontend/Dockerfile.temp << 'EOF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /usr/share/nginx/html
COPY dist/ /usr/share/nginx/html/
EXPOSE 3000
RUN sed -i 's/listen       80;/listen       3000;/g' /etc/nginx/conf.d/default.conf
CMD ["nginx", "-g", "daemon off;"]
EOF
            echo "📝 Dockerfile temporal creado para diagnóstico"
        fi
    fi
    
    echo "📦 Construyendo vidriera-web..."
    if docker-compose build --no-cache --progress=plain vidriera-web 2>&1 | tee /tmp/vidriera-build.log; then
        echo "✅ vidriera-web construido exitosamente"
    else
        echo "❌ Error construyendo vidriera-web"
        echo "📋 Últimas líneas del log de construcción:"
        tail -20 /tmp/vidriera-build.log
    fi
}

# Función para verificar archivos críticos
check_files() {
    echo "📁 Verificando archivos críticos..."
    
    # Verificar docker-entrypoint.sh con diagnóstico detallado
    ENTRYPOINT_FILE="GrowDesk/frontend/docker-entrypoint.sh"
    if [ -f "$ENTRYPOINT_FILE" ]; then
        echo "✅ docker-entrypoint.sh existe"
        
        # Información detallada del archivo
        echo "📋 Información detallada:"
        ls -la "$ENTRYPOINT_FILE"
        
        # Verificar contenido
        echo "📄 Primeras 3 líneas:"
        head -3 "$ENTRYPOINT_FILE"
        
        # Verificar permisos
        if [ -x "$ENTRYPOINT_FILE" ]; then
            echo "✅ Tiene permisos de ejecución"
        else
            echo "❌ No tiene permisos de ejecución"
        fi
        
        # Verificar codificación
        FILE_INFO=$(file "$ENTRYPOINT_FILE")
        echo "📝 Información del archivo: $FILE_INFO"
        
        if echo "$FILE_INFO" | grep -q "CRLF"; then
            echo "⚠️ Tiene terminaciones CRLF (Windows)"
        else
            echo "✅ Terminaciones de línea correctas (Unix)"
        fi
        
    else
        echo "❌ docker-entrypoint.sh no encontrado"
    fi
    
    # Verificar otros archivos críticos
    for file in "GrowDesk/frontend/Dockerfile" "Vidriera-Web/frontend/Dockerfile" "docker-compose.yml"; do
        if [ -f "$file" ]; then
            echo "✅ $file existe"
        else
            echo "❌ $file no encontrado"
        fi
    done
}

# Función para test rápido del entrypoint
test_entrypoint() {
    echo "🧪 Probando docker-entrypoint.sh localmente..."
    
    ENTRYPOINT_FILE="GrowDesk/frontend/docker-entrypoint.sh"
    if [ -f "$ENTRYPOINT_FILE" ]; then
        # Crear un entorno de prueba temporal
        TEMP_DIR=$(mktemp -d)
        mkdir -p "$TEMP_DIR/usr/share/nginx/html"
        echo "<html><body>Test</body></html>" > "$TEMP_DIR/usr/share/nginx/html/index.html"
        
        # Probar el script con variables de entorno de prueba
        export STATIC_DIR="$TEMP_DIR/usr/share/nginx/html"
        export VITE_API_URL="http://test-api"
        export VITE_SYNC_API_URL="http://test-sync"
        
        echo "🔧 Ejecutando test del entrypoint..."
        if timeout 10s bash -n "$ENTRYPOINT_FILE"; then
            echo "✅ Sintaxis del script correcta"
        else
            echo "❌ Error de sintaxis en el script"
        fi
        
        # Limpiar
        rm -rf "$TEMP_DIR"
        unset STATIC_DIR VITE_API_URL VITE_SYNC_API_URL
    else
        echo "❌ No se puede probar: archivo no encontrado"
    fi
}

# Función principal
main() {
    echo "🚀 Iniciando diagnóstico..."
    
    check_docker
    check_network
    check_files
    test_entrypoint
    
    echo ""
    echo "¿Qué deseas hacer?"
    echo "1) Limpiar y reconstruir todo"
    echo "2) Construir con diagnóstico detallado"
    echo "3) Solo reparar problemas del entrypoint"
    echo "4) Solo iniciar servicios"
    echo "5) Salir"
    
    read -p "Selecciona una opción (1-5): " choice
    
    case $choice in
        1)
            cleanup_docker
            fix_entrypoint_issues
            build_with_diagnostics
            echo "🚀 Iniciando servicios..."
            docker-compose up -d
            ;;
        2)
            build_with_diagnostics
            ;;
        3)
            fix_entrypoint_issues
            echo "✅ Problemas del entrypoint reparados"
            ;;
        4)
            echo "🚀 Iniciando servicios..."
            docker-compose up -d
            ;;
        5)
            echo "👋 Saliendo..."
            exit 0
            ;;
        *)
            echo "❌ Opción inválida"
            exit 1
            ;;
    esac
    
    echo ""
    echo "📊 Estado de los contenedores:"
    docker-compose ps
    
    echo ""
    echo "📋 Para ver logs en tiempo real:"
    echo "   docker-compose logs -f [nombre_servicio]"
    echo ""
    echo "🌐 URLs de acceso:"
    echo "   Frontend: http://localhost:3001"
    echo "   Vidriera Web: http://localhost:4321"
    echo "   API Gateway: http://localhost"
    
    # Verificar si hay contenedores con problemas
    if docker-compose ps | grep -q "Exit\|Restarting"; then
        echo ""
        echo "⚠️ Algunos contenedores tienen problemas. Logs recientes:"
        docker-compose logs --tail=10 frontend 2>/dev/null || true
    fi
}

# Ejecutar función principal
main 