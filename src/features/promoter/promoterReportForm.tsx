import { useState, useEffect } from 'preact/hooks';
import type { State, Client, Product } from '../../types';
import {
	fetchStates,
	fetchClientsByState,
	fetchProductsByClient,
} from '../../lib/queries';

type InventorySection = {
	units: number;
	packages: number;
};

type InventoryValues = Record<number, {
	initial: InventorySection;
	final: InventorySection;
}>;

export function PromoterReportForm() {
	const [states, setStates] = useState<Array<State>>([]);
	const [clients, setClients] = useState<Array<Client>>([]);
	const [products, setProducts] = useState<Array<Product>>([]);
	const [inventory, setInventory] = useState<InventoryValues>({});

	useEffect(() => {
		const loadStates = async() => {
			const states = await fetchStates();
			console.log('Estados cargados en el formulario:', states);
			setStates(states);
		}; 
		loadStates();
	}, []);

	const handleStateChange = async (event: Event) => {
		const select = event.currentTarget as HTMLElement & { value: string };
		const selectedStateId = Number(select.value);

		if (Number.isNaN(selectedStateId)) {
			console.warn('No se pudo obtener un state_id válido:', select.value);
			setClients([]);
			return;
		}

		console.log('Estado seleccionado:', selectedStateId);
		const clients = await fetchClientsByState(selectedStateId);

		console.log('Clientes cargados en el formulario:', clients);
		setClients(clients);
		setProducts([]);
		setInventory({});
	}

	const handleClientChange = async (event: Event) => {
		const select = event.currentTarget as HTMLElement & { value: string };
		const selectedClientId = select.value;

		if (!selectedClientId) {
			setProducts([]);
			setInventory({});
			return;
		}

		const products = await fetchProductsByClient(selectedClientId);
		setProducts(products);
		setInventory(
			Object.fromEntries(
				products.map((product) => [
					product.id,
					{
						initial: { units: 0, packages: 0 },
						final: { units: 0, packages: 0 },
					},
				]),
			),
		);
	};

	const handleInventoryChange = (
		productId: number,
		section: 'initial' | 'final',
		field: keyof InventorySection,
		value: string,
	) => {
		const numericValue = Math.max(0, Number(value) || 0);

		setInventory((current) => ({
			...current,
			[productId]: {
				...current[productId],
				[section]: {
					...current[productId]?.[section],
					[field]: numericValue,
				},
			},
		}));
	};

	const renderInventoryRows = (section: 'initial' | 'final') => (
		<div class="inventory-table" role="table" aria-label={section === 'initial' ? 'Inventario inicial' : 'Inventario final'}>
			<div class="inventory-row inventory-header" role="row">
				<span role="columnheader">Producto</span>
				<span role="columnheader">Unidad</span>
				<span role="columnheader">Bulto</span>
			</div>
			{products.map((product) => (
				<div class="inventory-row" role="row" key={`${section}-${product.id}`}>
					<span role="cell">{product.name}</span>
					<mdui-text-field
						type="number"
						min="0"
						value={String(inventory[product.id]?.[section].units ?? 0)}
						onInput={(event: Event) => {
							const input = event.currentTarget as HTMLElement & { value: string };
							handleInventoryChange(product.id, section, 'units', input.value);
						}}
					></mdui-text-field>
					<mdui-text-field
						type="number"
						min="0"
						value={String(inventory[product.id]?.[section].packages ?? 0)}
						onInput={(event: Event) => {
							const input = event.currentTarget as HTMLElement & { value: string };
							handleInventoryChange(product.id, section, 'packages', input.value);
						}}
					></mdui-text-field>
				</div>
			))}
		</div>
	);

	return (
		<form>
			<fieldset>
				<legend>Reporte General</legend>

				<label>
				Estado:
				<mdui-select placeholder="--Seleccione un estado--" icon="search" onChange={handleStateChange}>
					{
						states.map((state) => (
							<mdui-menu-item key={state.id} value={String(state.id)}>
								{state.name}
							</mdui-menu-item>
						))
					}
				</mdui-select>
				</label>

				<br></br>

				<label>
				Vendedor (Nombre y Apellido):
				<mdui-text-field icon="person" placeholder="--Ingrese nombre y apellido--"></mdui-text-field>
				</label>

				<br></br>
                
				<label>
				Mercaderista (Nombre y Apellido):
				<mdui-text-field  icon="person" placeholder="--Ingrese nombre y apellido--"></mdui-text-field>
				</label>

				<br></br>

				<label>
				Zona:
				<mdui-text-field icon="location_on" placeholder="--Ingrese zona--"></mdui-text-field>
				</label>

				<br></br>

				<label>
				Establecimiento:
				<mdui-text-field icon="store" placeholder="--Ingrese establecimiento--"></mdui-text-field>
				</label>

				<label>
				Cliente:
				<mdui-select placeholder="--Seleccione un cliente--" icon="search" onChange={handleClientChange}>
					{
						clients.map((client) => (
							<mdui-menu-item key={client.id} value={client.id}>
								{client.name}
							</mdui-menu-item>
						))
					}
				</mdui-select>
				</label>
			</fieldset>

			{
			<fieldset>
				<legend>Reporte de Inventario</legend>
				{products.length > 0 ? (
					<>
						<h3>Inventario inicial</h3>
						{renderInventoryRows('initial')}
						<h3>Inventario final</h3>
						{renderInventoryRows('final')}
					</>
				) : (
					<p>Seleccione un cliente para cargar sus productos.</p>
				)}
			</fieldset>
			}
		</form>
	)
}
