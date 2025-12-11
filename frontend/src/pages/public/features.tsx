import { Helmet } from 'react-helmet-async';

import { Grid, Paper, Container, Typography } from '@mui/material';

import { CONFIG } from 'src/config-global';

export default function FeaturesPage() {
  return (
    <>
      <Helmet>
        <title>Features | {CONFIG.appName}</title>
      </Helmet>

      <Container maxWidth="lg" sx={{ pt: 8, pb: 8 }}>
        <Typography variant="h3" component="h1" gutterBottom sx={{ fontWeight: 700 }}>
          Features
        </Typography>
        <Typography variant="h6" color="text.secondary" paragraph>
          Everything you need to build, deploy and scale AI assistants.
        </Typography>

        <Grid container spacing={3} sx={{ mt: 4 }}>
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Connectors</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Connect to Google Drive, Notion, S3, Slack and more to centralize your knowledge.
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Agents</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Create, train and chat with custom agents for different use-cases.
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </>
  );
}
