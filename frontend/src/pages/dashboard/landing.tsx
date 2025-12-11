import { Icon } from '@iconify/react';
import { Helmet } from 'react-helmet-async';
import { Link as RouterLink } from 'react-router-dom';

import {
  Box,
  Grid,
  Link,
  Paper,
  Stack,
  Button,
  AppBar,
  Toolbar,
  Divider,
  Container,
  Typography,
} from '@mui/material';

import { paths } from 'src/routes/paths';

import { CONFIG } from 'src/config-global';

import { Logo } from 'src/components/logo';

// Rich public landing page optimized for SaaS presentation
export default function LandingPage() {
  return (
    <>
      <Helmet>
        <title>{CONFIG.appName} — AI Assistant Platform</title>
      </Helmet>

      {/* Header */}
      <AppBar position="static" color="transparent" elevation={0} sx={{ mb: 4 }}>
        <Toolbar sx={{ justifyContent: 'space-between' }}>
          <Box display="flex" alignItems="center" gap={1}>
            <Logo />
            <Typography variant="h6" sx={{ fontWeight: 700 }}>
              {CONFIG.appName}
            </Typography>
          </Box>

          <Box>
            <Button component={RouterLink} to={paths.auth.jwt.signIn} variant="text" sx={{ mr: 1 }}>
              Sign in
            </Button>
            <Button component={RouterLink} to={paths.auth.jwt.signUp} variant="contained">
              Start free trial
            </Button>
          </Box>
        </Toolbar>
      </AppBar>

      {/* Hero */}
      <Container maxWidth="lg" sx={{ py: { xs: 6, md: 10 } }}>
        <Grid container spacing={6} alignItems="center">
          <Grid item xs={12} md={6}>
            <Typography variant="h2" component="h1" gutterBottom sx={{ fontWeight: 800 }}>
              Build smarter assistants. Ship faster.
            </Typography>
            <Typography variant="h6" color="text.secondary" paragraph>
              {CONFIG.appName} helps teams centralize knowledge, connect tools and deploy AI
              assistants that actually help get work done.
            </Typography>

            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mt: 3 }}>
              <Button
                component={RouterLink}
                to={paths.auth.jwt.signUp}
                variant="contained"
                size="large"
              >
                Start free trial
              </Button>
              <Button
                component={RouterLink}
                to={paths.dashboard.knowledgebase.search}
                variant="outlined"
                size="large"
              >
                Try Knowledge Search
              </Button>
            </Stack>

            <Typography variant="body2" color="text.secondary" sx={{ mt: 3 }}>
              No credit card required · 14-day trial · Cancel anytime
            </Typography>
          </Grid>

          <Grid item xs={12} md={6}>
            <Paper elevation={6} sx={{ p: 4, borderRadius: 3 }}>
              <Box
                sx={{
                  width: '100%',
                  height: 320,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {/* Illustration placeholder — replace with asset or SVG */}
                <Box sx={{ textAlign: 'center' }}>
                  <Typography variant="h6" sx={{ mb: 1 }}>
                    Live demo
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Chat with a sample assistant, explore knowledge search and connectors.
                  </Typography>
                  <Box sx={{ mt: 2 }}>
                    <Button
                      component={RouterLink}
                      to={`${paths.dashboard.root}agents`}
                      variant="contained"
                    >
                      Open Demo Assistant
                    </Button>
                  </Box>
                </Box>
              </Box>
            </Paper>
          </Grid>
        </Grid>
      </Container>

      <Divider />

      {/* Features */}
      <Container maxWidth="lg" sx={{ py: { xs: 6, md: 8 } }}>
        <Typography variant="h4" sx={{ fontWeight: 700, mb: 3 }}>
          Why teams choose {CONFIG.appName}
        </Typography>

        <Grid container spacing={3}>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Icon icon="mdi:flash" width={36} height={36} />
              <Typography variant="h6" sx={{ mt: 1, fontWeight: 600 }}>
                Fast setup
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Connect your sources and be answering questions in minutes.
              </Typography>
            </Paper>
          </Grid>

          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Icon icon="mdi:database" width={36} height={36} />
              <Typography variant="h6" sx={{ mt: 1, fontWeight: 600 }}>
                Unified knowledge
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Centralize documents, wikis and conversations for reliable answers.
              </Typography>
            </Paper>
          </Grid>

          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Icon icon="mdi:account-group" width={36} height={36} />
              <Typography variant="h6" sx={{ mt: 1, fontWeight: 600 }}>
                Team friendly
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Manage users, roles and permissions — deploy across teams and orgs.
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>

      <Divider />

      {/* Pricing teaser */}
      <Container maxWidth="lg" sx={{ py: { xs: 6, md: 8 } }}>
        <Typography variant="h4" sx={{ fontWeight: 700, mb: 3 }}>
          Simple, predictable pricing
        </Typography>

        <Grid container spacing={3}>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Free</Typography>
              <Typography sx={{ my: 2 }}>$0 — Trial</Typography>
              <Typography variant="body2" color="text.secondary">
                Basic features to get started.
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Pro</Typography>
              <Typography sx={{ my: 2 }}>$29 / month</Typography>
              <Typography variant="body2" color="text.secondary">
                For growing teams and production use.
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6">Enterprise</Typography>
              <Typography sx={{ my: 2 }}>Custom</Typography>
              <Typography variant="body2" color="text.secondary">
                SSO, SLA and dedicated support.
              </Typography>
            </Paper>
          </Grid>
        </Grid>

        <Box sx={{ textAlign: 'center', mt: 4 }}>
          <Button component={RouterLink} to={`${paths.dashboard.root}pricing`} variant="contained">
            View full pricing
          </Button>
        </Box>
      </Container>

      <Divider />

      {/* Testimonials */}
      <Container maxWidth="lg" sx={{ py: { xs: 6, md: 8 } }}>
        <Typography variant="h4" sx={{ fontWeight: 700, mb: 3 }}>
          What customers say
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                &ldquo;Saved us hours&rdquo;
              </Typography>
              <Typography variant="body2" color="text.secondary">
                &ldquo;{CONFIG.appName} reduced our support time by 40%.&rdquo;
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                &ldquo;Easy to integrate&rdquo;
              </Typography>
              <Typography variant="body2" color="text.secondary">
                &ldquo;Connectors made onboarding painless.&rdquo;
              </Typography>
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                &ldquo;Team friendly&rdquo;
              </Typography>
              <Typography variant="body2" color="text.secondary">
                &ldquo;Great roles and permissions for admins.&rdquo;
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>

      <Divider />

      {/* Footer */}
      <Box component="footer" sx={{ bgcolor: 'background.paper', py: 4, mt: 6 }}>
        <Container maxWidth="lg">
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={6}>
              <Box display="flex" alignItems="center" gap={1}>
                <Logo />
                <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                  {CONFIG.appName}
                </Typography>
              </Box>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                © {new Date().getFullYear()} {CONFIG.appName}. All rights reserved.
              </Typography>
            </Grid>
            <Grid item xs={12} md={6}>
              <Box display="flex" justifyContent={{ xs: 'flex-start', md: 'flex-end' }} gap={2}>
                <Link component={RouterLink} to="/features" underline="none">
                  Features
                </Link>
                <Link component={RouterLink} to="/pricing" underline="none">
                  Pricing
                </Link>
                <Link component={RouterLink} to={paths.auth.jwt.signIn} underline="none">
                  Sign in
                </Link>
              </Box>
            </Grid>
          </Grid>
        </Container>
      </Box>
    </>
  );
}
