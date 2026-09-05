import { useState } from 'preact/hooks';
import DashboardLayout from './DashboardLayout';

import AdminHome from './tabs/AdminHome';
import AdminReports from './tabs/AdminReports';
import AdminUsers from './tabs/AdminUsers';

interface Props {
  userName: string;
}

export default function AdminDashboard({ userName }: Props) {
  const [activeTab, setActiveTab] = useState('home');

  const navItems = [
    { value: 'home', icon: 'home', label: 'Inicio' },
    { value: 'reports', icon: 'analytics', label: 'Reportes' },
    { value: 'users', icon: 'manage_accounts', label: 'Usuarios' }
  ];

  return (
    <DashboardLayout
      activeTab={activeTab}
      onTabChange={setActiveTab}
      navItems={navItems}
    >
      {activeTab === 'home' && <AdminHome userName={userName} role="administrator" />}
      {activeTab === 'reports' && <AdminReports />}
      {activeTab === 'users' && <AdminUsers />}
    </DashboardLayout>
  );
}