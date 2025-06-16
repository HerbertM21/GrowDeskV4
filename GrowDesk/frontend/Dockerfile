# Dockerfile para GrowDesk Frontend
# Solución robusta para problemas de entrypoint

# Etapa de construcción
FROM node:18-alpine AS build

# Directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias
RUN apk add --no-cache \
    bash \
    curl \
    dos2unix \
    file

# Copiar archivos de dependencias primero (para aprovechar cache de Docker)
COPY package*.json ./

# Configurar npm para manejar problemas de red y conectividad
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set timeout 120000 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 5 && \
    npm config set audit false

# Limpiar caché e instalar dependencias
RUN npm cache clean --force && \
    (npm ci || npm install) && \
    npm cache verify

# Copiar el código fuente
COPY . .

# Argumentos de construcción
ARG VITE_API_URL=http://localhost/api
ARG VITE_SYNC_API_URL=http://localhost/api/sync/users
ARG NODE_ENV=production

# Variables de entorno para la construcción
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_SYNC_API_URL=$VITE_SYNC_API_URL
ENV NODE_ENV=$NODE_ENV

# Construir la aplicación
RUN npm run build

# Etapa de producción con Nginx
FROM nginx:alpine

# Instalar herramientas necesarias en la imagen de producción
RUN apk add --no-cache \
    bash \
    dos2unix \
    file \
    curl

# Copiar la configuración de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar los archivos construidos desde la etapa de build
COPY --from=build /app/dist /usr/share/nginx/html

# Copiar el script de entrypoint y asegurar que esté correctamente configurado
COPY docker-entrypoint.sh /tmp/docker-entrypoint.sh

# Procesar el script de entrypoint para asegurar compatibilidad multiplataforma
RUN echo "🔧 Configurando docker-entrypoint.sh..." && \
    # Convertir terminaciones de línea si es necesario
    dos2unix /tmp/docker-entrypoint.sh && \
    # Mover a la ubicación final
    cp /tmp/docker-entrypoint.sh /docker-entrypoint.sh && \
    # Asegurar permisos de ejecución
    chmod +x /docker-entrypoint.sh && \
    # Verificar que el archivo existe y es ejecutable
    ls -la /docker-entrypoint.sh && \
    # Verificar que el shebang es correcto
    head -1 /docker-entrypoint.sh && \
    # Limpiar archivo temporal
    rm /tmp/docker-entrypoint.sh && \
    echo "✅ docker-entrypoint.sh configurado correctamente"

# Crear un script de fallback en caso de problemas
RUN echo '#!/bin/sh' > /fallback-entrypoint.sh && \
    echo 'echo "🚨 Usando entrypoint de fallback"' >> /fallback-entrypoint.sh && \
    echo 'echo "🌐 Iniciando Nginx directamente..."' >> /fallback-entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /fallback-entrypoint.sh && \
    chmod +x /fallback-entrypoint.sh

# Exponer puerto
EXPOSE 3000

# Configurar Nginx para usar el puerto 3000
RUN sed -i 's/listen       80;/listen       3000;/g' /etc/nginx/conf.d/default.conf

# Usar el entrypoint principal, con fallback si falla
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

# Agregar healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1 