#!/bin/bash

echo "🎨 Script de reconstrucción del Frontend con PrimeVue"
echo "===================================================="

# Función para verificar dependencias de PrimeVue
check_primevue_deps() {
    echo "📦 Verificando dependencias de PrimeVue..."
    
    cd GrowDesk/frontend
    
    # Verificar que las dependencias estén en package.json
    if grep -q "primevue" package.json; then
        echo "✅ PrimeVue encontrado en package.json"
        grep "primevue\|primeicons\|primeflex" package.json
    else
        echo "❌ PrimeVue no encontrado en package.json"
        return 1
    fi
    
    # Verificar node_modules
    if [ -d "node_modules/primevue" ]; then
        echo "✅ PrimeVue instalado en node_modules"
    else
        echo "⚠️ PrimeVue no encontrado en node_modules, será instalado durante build"
    fi
    
    cd ../..
}

# Función para limpiar solo el frontend
cleanup_frontend() {
    echo "🧹 Limpiando contenedor frontend..."
    
    # Detener solo el frontend
    docker-compose stop frontend 2>/dev/null || true
    
    # Eliminar contenedor frontend
    docker-compose rm -f frontend 2>/dev/null || true
    
    # Eliminar imagen del frontend
    docker images | grep -E "growdesk.*frontend" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    
    echo "✅ Frontend limpiado"
}

# Función para construir solo el frontend
build_frontend() {
    echo "🔨 Construyendo frontend con PrimeVue..."
    
    # Construir con logs detallados
    if docker-compose build --no-cache --progress=plain frontend 2>&1 | tee frontend-build.log; then
        echo "✅ Frontend construido exitosamente"
        return 0
    else
        echo "❌ Error construyendo frontend"
        echo "📋 Últimas líneas del log:"
        tail -20 frontend-build.log
        return 1
    fi
}

# Función para iniciar solo el frontend
start_frontend() {
    echo "🚀 Iniciando frontend..."
    
    if docker-compose up -d frontend; then
        echo "✅ Frontend iniciado"
        
        # Esperar que se inicie
        echo "⏳ Esperando que el frontend se inicie..."
        sleep 10
        
        # Verificar estado
        echo "📊 Estado del frontend:"
        docker-compose ps frontend
        
        # Mostrar logs
        echo "📋 Logs del frontend:"
        docker-compose logs --tail=15 frontend
        
    else
        echo "❌ Error al iniciar frontend"
        return 1
    fi
}

# Función para verificar PrimeVue en el navegador
test_primevue() {
    echo "🧪 Verificando PrimeVue..."
    
    # Esperar un poco más para que cargue completamente
    sleep 5
    
    if curl -f -s --max-time 10 "http://localhost:3001" > /dev/null 2>&1; then
        echo "✅ Frontend accesible en http://localhost:3001"
        
        # Verificar que los archivos CSS de PrimeVue se están sirviendo
        echo "🔍 Verificando archivos estáticos..."
        
        # Obtener el HTML y buscar referencias a PrimeVue
        HTML_CONTENT=$(curl -s --max-time 5 "http://localhost:3001" 2>/dev/null || echo "")
        
        if echo "$HTML_CONTENT" | grep -q "primevue\|primeicons"; then
            echo "✅ Referencias a PrimeVue encontradas en el HTML"
        else
            echo "⚠️ No se encontraron referencias directas a PrimeVue en el HTML"
            echo "   (Esto es normal si están bundleados en el JS)"
        fi
        
        # Verificar que el JavaScript principal se carga
        if echo "$HTML_CONTENT" | grep -q "\.js"; then
            echo "✅ Archivos JavaScript encontrados"
        else
            echo "⚠️ No se encontraron archivos JavaScript"
        fi
        
    else
        echo "❌ Frontend no accesible en http://localhost:3001"
        echo "📋 Logs de error:"
        docker-compose logs --tail=10 frontend
        return 1
    fi
}

# Función para mostrar información de debugging
show_debug_info() {
    echo ""
    echo "🔍 Información de debugging:"
    echo "=========================="
    
    # Verificar archivos en el contenedor
    echo "📁 Archivos en el contenedor:"
    docker-compose exec frontend ls -la /usr/share/nginx/html/ 2>/dev/null || echo "No se pudo acceder al contenedor"
    
    # Verificar configuración de Nginx
    echo ""
    echo "⚙️ Configuración de Nginx:"
    docker-compose exec frontend cat /etc/nginx/conf.d/default.conf 2>/dev/null || echo "No se pudo leer configuración de Nginx"
    
    # Verificar procesos en el contenedor
    echo ""
    echo "🔄 Procesos en el contenedor:"
    docker-compose exec frontend ps aux 2>/dev/null || echo "No se pudo listar procesos"
}

# Función principal
main() {
    echo "🚀 Iniciando reconstrucción del frontend..."
    
    # Verificar que estamos en el directorio correcto
    if [ ! -f "docker-compose.yml" ]; then
        echo "❌ Error: No se encontró docker-compose.yml"
        echo "💡 Asegúrate de ejecutar este script desde el directorio raíz del proyecto"
        exit 1
    fi
    
    # Ejecutar pasos
    check_primevue_deps || exit 1
    cleanup_frontend
    build_frontend || exit 1
    start_frontend || exit 1
    test_primevue
    
    echo ""
    echo "🎉 ¡Reconstrucción del frontend completada!"
    echo ""
    echo "🌐 Accede al frontend en: http://localhost:3001"
    echo ""
    echo "📋 Comandos útiles:"
    echo "   Ver logs: docker-compose logs -f frontend"
    echo "   Reiniciar: docker-compose restart frontend"
    echo "   Detener: docker-compose stop frontend"
    echo ""
    
    # Preguntar si mostrar información de debugging
    read -p "¿Mostrar información de debugging? (y/N): " show_debug
    if [[ $show_debug =~ ^[Yy]$ ]]; then
        show_debug_info
    fi
    
    echo ""
    echo "💡 Si los estilos no se ven correctamente:"
    echo "   1. Abre las herramientas de desarrollador (F12)"
    echo "   2. Ve a la pestaña Network/Red"
    echo "   3. Recarga la página (Ctrl+F5)"
    echo "   4. Verifica que los archivos CSS se cargan sin errores"
}

# Ejecutar función principal
main 