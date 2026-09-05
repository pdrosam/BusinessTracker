import { useState } from 'preact/hooks';
import DashboardLayout from './DashboardLayout';

// Import the tab components
import PromoterHome from './tabs/PromoterHome';
import PromoterSales from './tabs/PromoterSales';
import PromoterZones from './tabs/PromoterZones';

interface Props {
  userName: string;
}

export default function PromoterDashboard({ userName }: Props) {
  // State to track which tab is currently selected
  const [activeTab, setActiveTab] = useState('home');

  // Define the navigation items for this specific role
  const navItems = [
    { value: 'home', icon: 'home', label: 'Inicio' },
    { value: 'sales', icon: 'receipt_long', label: 'Mis Ventas' },
    { value: 'zones', icon: 'place', label: 'Zonas' }
  ];

  return (
    <DashboardLayout
      activeTab={activeTab}
      onTabChange={setActiveTab}
      navItems={navItems}
    >
      {/* Conditional Rendering: Only show the component that matches activeTab */}
      {activeTab === 'home' && <PromoterHome userName={userName} role="promoter" />}
      {activeTab === 'sales' && <PromoterSales />}
      {activeTab === 'zones' && <PromoterZones />}
    </DashboardLayout>
  );
}