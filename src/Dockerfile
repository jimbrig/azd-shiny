# Use the official Rocker Shiny image as base
FROM rocker/shiny:latest

# Set working directory
WORKDIR /srv/shiny-server

# Install additional R packages
RUN R -e "install.packages(c('DT'), repos='https://cran.rstudio.com/')"

# Copy the R Shiny application
COPY app.R ./

# Create a non-root user for security
RUN groupadd -r shiny && useradd -r -g shiny shiny

# Set proper permissions
RUN chown -R shiny:shiny /srv/shiny-server
RUN chmod -R 755 /srv/shiny-server

# Expose port 3838 (Shiny default)
EXPOSE 3838

# Use the non-root user
USER shiny

# Health check to ensure the app is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3838/ || exit 1

# Start the Shiny server
CMD ["/usr/bin/shiny-server"]
