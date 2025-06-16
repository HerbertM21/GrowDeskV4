# Dockerfile para Vidriera Web (Astro)
FROM node:18-alpine as builder

WORKDIR /app

# Instalar herramientas necesarias
RUN apk add --no-cache git

# Configurar npm para manejar problemas de red
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 5 && \
    npm config set audit false && \
    npm config set fund false

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias con manejo de errores
RUN npm cache clean --force && \
    (npm ci || npm install) && \
    npm cache clean --force

# Copiar el código fuente
COPY . .

# Construir la aplicación con manejo de errores
RUN npm run build || (echo "Error en build, intentando nuevamente..." && npm run build)

# Etapa de producción
FROM nginx:alpine

# Configurar Nginx para servir archivos estáticos y manejar rutas
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/

# Copiar los archivos construidos
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar archivos del widget al directorio público
COPY --from=builder /app/public /usr/share/nginx/html

# Exponer el puerto
EXPOSE 4321

# Comando para ejecutar nginx
CMD ["nginx", "-g", "daemon off;"] 