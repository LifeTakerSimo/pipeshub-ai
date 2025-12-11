import { Helmet } from 'react-helmet-async';
import { Link as RouterLink } from 'react-router-dom';

import { Box, Grid, Paper, Button, Container, Typography } from '@mui/material';

import { paths } from 'src/routes/paths';

import { CONFIG } from 'src/config-global';

export default function PricingPage() {
  return (
    <>
      <Helmet>
        <title>Pricing | {CONFIG.appName}</title>
      </Helmet>

      <Container maxWidth="lg" sx={{ pt: 8, pb: 8 }}>
        <Typography variant="h3" component="h1" gutterBottom sx={{ fontWeight: 700 }}>
          Plans & Pricing
        </Typography>
        <Typography variant="h6" color="text.secondary" paragraph>
          Simple, predictable pricing. Start with a free trial and upgrade when you’re ready.
        </Typography>

        <Grid container spacing={3} sx={{ mt: 4 }}>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Free</Typography>
              <Typography sx={{ my: 2 }}>$0 — Trial</Typography>
              <Typography variant="body2" color="text.secondary">
                Basic features, limited usage — perfect to try things out.
              </Typography>
              <Box sx={{ mt: 2 }}>
                <Button
                  component={RouterLink}
                  to={paths.auth.jwt.signUp}
                  variant="contained"
                  fullWidth
                >
                  Start free
                </Button>
              </Box>
            </Paper>
          </Grid>

          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Pro</Typography>
              <Typography sx={{ my: 2 }}>$29 / month</Typography>
              <Typography variant="body2" color="text.secondary">
                More requests, priority support, and team features.
              </Typography>
              <Box sx={{ mt: 2 }}>
                <Button variant="outlined" fullWidth>
                  Get started
                </Button>
              </Box>
            </Paper>
          </Grid>

          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Enterprise</Typography>
              <Typography sx={{ my: 2 }}>Custom</Typography>
              <Typography variant="body2" color="text.secondary">
                Custom plans with SSO, dedicated support and SLAs.
              </Typography>
              <Box sx={{ mt: 2 }}>
                <Button variant="outlined" fullWidth>
                  Contact sales
                </Button>
              </Box>
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </>
  );
}
