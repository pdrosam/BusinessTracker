import { supabase } from './supabaseClient';

export const fetchStates = async () => {
    const {data: states, error: fetchStatesError} = await supabase
        .from('states')
        .select('id, name');

    console.log('fetchStates:', { states, error: fetchStatesError });

    if (fetchStatesError) {
        console.error('Error fetching states:', fetchStatesError);
        return [];
    }

    return states ?? [];
};

export const fetchClientsByState = async (selectedStateId: number) => {
    const {data: clients, error: fetchClientsError} = await supabase
        .from('clients_states')
        .select('clients(id, name)')
        .eq('state_id', selectedStateId);

    console.log('fetchClientsByState:', {
        selectedStateId,
        clients,
        error: fetchClientsError,
    });

    if (fetchClientsError) {
        console.error('Error fetching clients:', fetchClientsError);
        return [];
    }

    return (clients ?? []).flatMap((item) => {
        if (Array.isArray(item.clients)) {
            return item.clients;
        }

        return item.clients ? [item.clients] : [];
    });
};

export const fetchProductsByClient = async (selectedClientId: String) => {
    const {data: products, error: fetchProductsError} = await supabase
        .from('products')
        .select('id, name, client_id, units_per_package')
        .eq('client_id', selectedClientId)
        .order('name');

    console.log('fetchProductsByClient:', {
        selectedClientId,
        products,
        error: fetchProductsError,
    });

    if (fetchProductsError)
    {
        console.error('Error fetching products:', fetchProductsError)
        return [];
    }

    return products ?? [];
};