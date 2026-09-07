export interface State {
    id: number;
    name: string;
}

export interface Client {
    id: string;
    name: string;
    rif?: string;
}

export interface Product {
    id: number;
    name: string;
    client_id?: string;
    units_per_package: number;
}

