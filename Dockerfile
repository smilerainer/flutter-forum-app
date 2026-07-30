# --- build stage ---
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
ARG SUPABASE_URL
ARG SUPABASE_PUBLISHABLE_KEY
RUN flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY

# --- serve stage ---
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80