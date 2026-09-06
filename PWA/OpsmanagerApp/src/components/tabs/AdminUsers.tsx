import { useEffect, useState } from 'preact/hooks';
import 'mdui/components/avatar.js';
import 'mdui/components/badge.js';
import 'mdui/components/button.js';
import 'mdui/components/button-icon.js';
import 'mdui/components/divider.js';

import AdminUserCreation from './AdminUserCreation';
import { supabase } from '../../lib/supabase';

interface UserItem {
  id: string;
  first_name: string;
  last_name: string;
  role: string;
  is_active: boolean;
}

export default function AdminUsers() {
  const [users, setUsers] = useState<UserItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [createFeedbackMsg, setCreateFeedbackMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const reloadUsers = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('profiles')
      .select('id,first_name,last_name,role,is_active')
      .order('first_name', { ascending: true });

    if (error) {
      console.error('Failed to load users', error.message);
      setUsers([]);
    } else if (data) {
      setUsers(data as UserItem[]);
    }

    setLoading(false);
  };

  useEffect(() => {
    let mounted = true;
    // initial load
    (async () => {
      if (!mounted) return;
      await reloadUsers();
    })();
    return () => { mounted = false; };
  }, []);

  return (
    <div>
      <div class="list-header" >
        <h3 style={{ margin: 0 }}>Users</h3>
        <mdui-button variant="filled" onClick={() => setShowCreate(true)}>Create user</mdui-button>
      </div>
      {/* <mdui-divider></mdui-divider> */}

        {showCreate ? (
            <div class="dialog-panel">
              <mdui-button variant="outlined" onClick={() => setShowCreate(false)} style={{ marginBottom: '8px' }}>Back to list</mdui-button>
              <AdminUserCreation onCreated={(msg) => {
                setCreateFeedbackMsg(msg);
                setShowCreate(false);
                // reload users list after a new user is created
                reloadUsers();
              }} />
            </div>
        ) : null}

      {createFeedbackMsg && (
        <div class={`feedback-message ${createFeedbackMsg.type === 'error' ? 'error' : 'success'}`}>{createFeedbackMsg.text}</div>
      )}

      {loading && <p>Loading users...</p>}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {users.map((u) => (
          <div class="user-box" key={u.id}>
            <mdui-avatar src="/favicon.svg"></mdui-avatar>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 600 }}>{u.first_name} {u.last_name}</div>
              <mdui-badge style={{ marginTop: '4px' }}>{u.role.charAt(0).toUpperCase() + u.role.slice(1)}</mdui-badge>
            </div>

            <div style={{ display: 'flex', gap: '8px' }}>
              <mdui-button-icon icon="edit" variant="outlined" onClick={() => console.log('Edit', u.id)}></mdui-button-icon>
              <mdui-button-icon icon="settings" variant="filled" onClick={() => console.log('Manage', u.id)}></mdui-button-icon>
            </div>
            <mdui-divider middle></mdui-divider>
          </div>
        ))}

        {!loading && users.length === 0 && (
          <div style={{ padding: '12px', borderRadius: '6px' }}>No users found.</div>
        )}
      </div>
    </div>
  );
}
