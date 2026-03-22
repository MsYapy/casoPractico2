FROM nginx:alpine

# Instalar openssl y apache2-utils para htpasswd
RUN apk add --no-cache openssl apache2-utils

# Crear directorio para certificados
RUN mkdir -p /etc/nginx/ssl

# Generar certificado autofirmado
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=CasoPractico2/CN=localhost"

# Crear usuario htpasswd (usuario: admin, password: admin123)
RUN htpasswd -cb /etc/nginx/.htpasswd admin admin123

# Copiar configuración nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copiar contenido web personalizado
COPY html /usr/share/nginx/html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
