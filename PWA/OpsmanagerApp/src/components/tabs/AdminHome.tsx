import 'mdui/components/button.js';
import HomeUserBox from '../HomeUserBox';

interface Props {
  userName: string;
  role: string;
}

export default function AdminHome({ userName, role }: Props) {
  return (
    <div class="home-box">
      <HomeUserBox userName={userName} role={role} />
      <mdui-button variant="filled" icon="dashboard">
        Assign Tasks
      </mdui-button>
      <mdui-button variant="outlined" icon="analytics">
        View Reports
      </mdui-button>
      <mdui-button variant="outlined" icon="manage_accounts">
        Manage Users
      </mdui-button>
    </div>
  );
}
