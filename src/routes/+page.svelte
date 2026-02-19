<script lang="ts">
	type Response = {
		name: string;
		choice: 'Yes' | 'No';
		timestamp: Date;
	};

	let responses = $state<Response[]>([]);
	let showModal = $state(false);
	let selectedChoice = $state<'Yes' | 'No' | null>(null);
	let userName = $state('');

	function handleChoice(choice: 'Yes' | 'No') {
		selectedChoice = choice;
		showModal = true;
	}

	function handleSubmit() {
		if (userName.trim() && selectedChoice) {
			responses = [
				...responses,
				{
					name: userName.trim(),
					choice: selectedChoice,
					timestamp: new Date()
				}
			];
			closeModal();
		}
	}

	function closeModal() {
		showModal = false;
		userName = '';
		selectedChoice = null;
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Enter') {
			handleSubmit();
		}
	}
</script>

<div class="min-h-screen bg-base-200 p-8">
	<div class="max-w-4xl mx-auto">
		<!-- Header -->
		<div class="text-center mb-12">
			<h1 class="text-5xl font-bold mb-4">Yes or No Survey</h1>
			<p class="text-lg text-base-content/70">Make your choice and let us know who you are!</p>
		</div>

		<!-- Yes/No Buttons -->
		<div class="flex gap-6 justify-center mb-12">
			<button
				onclick={() => handleChoice('Yes')}
				class="btn btn-success btn-lg text-xl px-12 py-8 h-auto"
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-8 w-8 mr-2"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M5 13l4 4L19 7"
					/>
				</svg>
				Yes
			</button>
			<button
				onclick={() => handleChoice('No')}
				class="btn btn-error btn-lg text-xl px-12 py-8 h-auto"
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-8 w-8 mr-2"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M6 18L18 6M6 6l12 12"
					/>
				</svg>
				No
			</button>
		</div>

		<!-- Responses List -->
		{#if responses.length > 0}
			<div class="card bg-base-100 shadow-xl">
				<div class="card-body">
					<h2 class="card-title text-2xl mb-4">Responses ({responses.length})</h2>
					<div class="overflow-x-auto">
						<table class="table table-zebra">
							<thead>
								<tr>
									<th>Name</th>
									<th>Choice</th>
									<th>Time</th>
								</tr>
							</thead>
							<tbody>
								{#each responses.reverse() as response}
									<tr>
										<td class="font-semibold">{response.name}</td>
										<td>
											{#if response.choice === 'Yes'}
												<span class="badge badge-success gap-2">
													<svg
														xmlns="http://www.w3.org/2000/svg"
														class="h-4 w-4"
														fill="none"
														viewBox="0 0 24 24"
														stroke="currentColor"
													>
														<path
															stroke-linecap="round"
															stroke-linejoin="round"
															stroke-width="2"
															d="M5 13l4 4L19 7"
														/>
													</svg>
													Yes
												</span>
											{:else}
												<span class="badge badge-error gap-2">
													<svg
														xmlns="http://www.w3.org/2000/svg"
														class="h-4 w-4"
														fill="none"
														viewBox="0 0 24 24"
														stroke="currentColor"
													>
														<path
															stroke-linecap="round"
															stroke-linejoin="round"
															stroke-width="2"
															d="M6 18L18 6M6 6l12 12"
														/>
													</svg>
													No
												</span>
											{/if}
										</td>
										<td class="text-base-content/60">
											{response.timestamp.toLocaleTimeString()}
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				</div>
			</div>
		{:else}
			<div class="text-center text-base-content/50 py-8">
				<p class="text-lg">No responses yet. Be the first to vote!</p>
			</div>
		{/if}
	</div>
</div>

<!-- Modal -->
{#if showModal}
	<div class="modal modal-open">
		<div class="modal-box">
			<h3 class="font-bold text-2xl mb-4">What's your name?</h3>
			<p class="mb-4 text-base-content/70">
				You selected: <span
					class="font-bold {selectedChoice === 'Yes' ? 'text-success' : 'text-error'}"
					>{selectedChoice}</span>
			</p>
			<input
				type="text"
				bind:value={userName}
				onkeydown={handleKeydown}
				placeholder="Enter your name"
				class="input input-bordered w-full mb-4"
				autofocus
			/>
			<div class="modal-action">
				<button onclick={closeModal} class="btn btn-ghost">Cancel</button>
				<button onclick={handleSubmit} class="btn btn-primary" disabled={!userName.trim()}>
					Submit
				</button>
			</div>
		</div>
		<div class="modal-backdrop" onclick={closeModal}></div>
	</div>
{/if}
