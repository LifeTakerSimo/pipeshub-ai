import { paths } from 'src/routes/paths';

// Base navigation items (without auth-dependent entries)
const baseNavItems = [
  { title: 'Assistant', path: paths.dashboard.root },
  {
    title: 'Knowledge Base',
    path: paths.dashboard.knowledgebase.root,
  },
  {
    title: 'Knowledge Search',
    path: paths.dashboard.knowledgebase.search,
  },
];

// Function to get navigation data based on user role
export const getDashboardNavData = (
  accountType: string | undefined,
  isAdmin: boolean,
  authenticated = true
) => {
  const isBusiness = accountType === 'business' || accountType === 'organization';

  // Start from the base items and wrap in the overview section
  const overviewItems = [...baseNavItems];

  // Only show the public Landing link to unauthenticated users (guests)
  if (!authenticated) {
    overviewItems.unshift({ title: 'Landing', path: paths.dashboard.agent.landing });
  }

  const navigationData: Array<{ subheader: string; items: typeof overviewItems }> = [
    {
      subheader: 'Overview',
      items: overviewItems,
    },
  ];

  if (isBusiness && isAdmin) {
    navigationData.push({
      subheader: 'Administration',
      items: [
        {
          title: 'Connector Settings',
          path: '/account/company-settings/settings/connector',
        },
      ],
    });
  } else if (!isBusiness) {
    navigationData.push({
      subheader: 'Settings',
      items: [
        {
          title: 'Connector Settings',
          path: '/account/individual/settings/connector',
        },
      ],
    });
  }

  return navigationData;
};

// Default export for backward compatibility
export const navData = [
  {
    subheader: 'Overview',
    items: baseNavItems,
  },
];
